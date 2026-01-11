//
//  SolsticeWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import CoreLocation
import Solar

fileprivate actor LocationManager {
	static let shared = LocationManager()

	private var cachedLocation: CLLocation?
	private var cacheTimestamp: Date?
	private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

	/// Returns cached location if valid, otherwise fetches a new one
	func getLocation() async -> CLLocation? {
		// Return cached location if still valid
		if let cachedLocation,
		   let cacheTimestamp,
		   Date().timeIntervalSince(cacheTimestamp) < cacheValidityDuration {
			return cachedLocation
		}

		// Fetch fresh location with timeout
		do {
			let location = try await fetchLocationWithTimeout(seconds: 10)
			cachedLocation = location
			cacheTimestamp = Date()
			return location
		} catch {
			// Fall back to cached location even if expired, or CLLocationManager's last known location
			return cachedLocation ?? CLLocationManager().location
		}
	}

	private func fetchLocationWithTimeout(seconds: TimeInterval) async throws -> CLLocation {
		try await withThrowingTaskGroup(of: CLLocation.self) { group in
			group.addTask {
				for try await update in CLLocationUpdate.liveUpdates() {
					if let location = update.location {
						return location
					}
				}
				throw CLError(.locationUnknown)
			}

			group.addTask {
				try await Task.sleep(for: .seconds(seconds))
				throw CLError(.locationUnknown)
			}

			let result = try await group.next()!
			group.cancelAll()
			return result
		}
	}
}

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation?
	var relevance: TimelineEntryRelevance?
}

protocol SolsticeWidgetTimelineProvider: IntentTimelineProvider where Entry == SolsticeWidgetTimelineEntry, Intent == ConfigurationIntent {
	var geocoder: CLGeocoder { get }
	static var widgetKind: SolsticeWidgetKind { get }
}

extension SolsticeWidgetTimelineProvider {
	func getLocation(for placemark: CLPlacemark? = nil, isRealLocation: Bool = false) -> SolsticeWidgetLocation {
		guard let placemark,
					let location = placemark.location else {
			return .defaultLocation
		}

		return SolsticeWidgetLocation(title: placemark.locality,
																	subtitle: placemark.country,
																	timeZoneIdentifier: placemark.timeZone?.identifier,
																	latitude: location.coordinate.latitude,
																	longitude: location.coordinate.longitude,
																	isRealLocation: isRealLocation)
	}

	/// Fetches location and reverse geocodes it to a placemark
	private func fetchWidgetLocation(for configuration: ConfigurationIntent) async -> (placemark: CLPlacemark?, isRealLocation: Bool) {
		let isRealLocation = (configuration.locationType == .currentLocation) || (configuration.locationType == .unknown)

		let location: CLLocation?
		switch configuration.locationType {
		case .customLocation:
			location = configuration.location?.location
		default:
			location = await LocationManager.shared.getLocation()
		}

		guard let location else {
			return (nil, isRealLocation)
		}

		let placemark = try? await geocoder.reverseGeocodeLocation(location).first
		return (placemark, isRealLocation)
	}

	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> Void) {
		Task {
			let (placemark, isRealLocation) = await fetchWidgetLocation(for: configuration)
			let widgetLocation = getLocation(for: placemark, isRealLocation: isRealLocation)
			let entry = SolsticeWidgetTimelineEntry(date: Date(), location: widgetLocation)
			completion(entry)
		}
	}

	func getTimeline(for configuration: Intent, in context: TimelineProviderContext, completion: @escaping (Timeline<Entry>) -> Void) {
		Task {
			let (placemark, isRealLocation) = await fetchWidgetLocation(for: configuration)
			let widgetLocation = getLocation(for: placemark, isRealLocation: isRealLocation)

			let currentDate = Date()
			var entries: [Entry] = []

			guard let solar = Solar(for: currentDate, coordinate: widgetLocation.coordinate) else {
				completion(Timeline(entries: [SolsticeWidgetTimelineEntry(date: currentDate, location: widgetLocation)], policy: .after(currentDate.endOfDay)))
				return
			}

			// Generate entries at key times rather than every 30 minutes
			var keyTimes = [
				currentDate,
				solar.safeSunrise.addingTimeInterval(-30 * 60),  // 30 min before sunrise
				solar.safeSunrise,
				solar.safeSunrise.addingTimeInterval(30 * 60),   // 30 min after sunrise
				solar.safeSunset.addingTimeInterval(-30 * 60),   // 30 min before sunset
				solar.safeSunset,
				solar.safeSunset.addingTimeInterval(30 * 60),    // 30 min after sunset
				currentDate.endOfDay
			]
			if let solarNoon = solar.solarNoon {
				keyTimes.append(solarNoon)
			}
			keyTimes = keyTimes.filter { $0 >= currentDate }

			for entryDate in keyTimes {
				let distanceToSunrise = abs(entryDate.distance(to: solar.safeSunrise))
				let distanceToSunset = abs(entryDate.distance(to: solar.safeSunset))
				let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
				let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
					? .init(score: 10, duration: nearestEventDistance)
					: nil

				entries.append(
					SolsticeWidgetTimelineEntry(
						date: entryDate,
						location: widgetLocation,
						relevance: relevance
					)
				)
			}

			// Sort and deduplicate entries that are too close together
			entries = entries
				.sorted { $0.date < $1.date }
				.reduce(into: [Entry]()) { result, entry in
					if let last = result.last, entry.date.timeIntervalSince(last.date) < 60 {
						return // Skip entries less than 1 minute apart
					}
					result.append(entry)
				}

			completion(Timeline(entries: entries, policy: .after(solar.nextSolarEvent?.date ?? currentDate.endOfDay)))
		}
	}

	func placeholder(in context: Context) -> SolsticeWidgetTimelineEntry {
		SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation)
	}
}

extension SolsticeWidgetTimelineEntry {
	static func previewTimeline() async -> [SolsticeWidgetTimelineEntry] {
		[
		SolsticeWidgetTimelineEntry(date: .now, location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 6), location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 12), location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 18), location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 24), location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 30), location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36), location: .defaultLocation)
		]
	}
}
