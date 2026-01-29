//
//  SolsticeWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import CoreLocation
import Solar

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation?
	var relevance: TimelineEntryRelevance?
	var locationError: LocationError?
}

enum LocationError: Error {
	case notAuthorized, locationUpdateFailed, reverseGeocodingFailed
}

struct SolsticeTimelineProvider: IntentTimelineProvider {
	typealias Entry = SolsticeWidgetTimelineEntry
	typealias Intent = ConfigurationIntent

	let widgetKind: SolsticeWidgetKind
	let recommendationDescription: String
	private let geocoder = CLGeocoder()

	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		[IntentRecommendation(intent: ConfigurationIntent(), description: recommendationDescription)]
	}

	private func getLocation(for placemark: CLPlacemark? = nil, isRealLocation: Bool = false) -> SolsticeWidgetLocation? {
		guard let placemark,
					let location = placemark.location else {
			return isRealLocation ? nil : .defaultLocation
		}

		return SolsticeWidgetLocation(title: placemark.locality,
																	subtitle: placemark.country,
																	timeZoneIdentifier: placemark.timeZone?.identifier,
																	latitude: location.coordinate.latitude,
																	longitude: location.coordinate.longitude,
																	isRealLocation: isRealLocation)
	}

	/// Fetches location and reverse geocodes it to a placemark
	private func fetchWidgetLocation(for configuration: ConfigurationIntent) async -> (placemark: CLPlacemark?, isRealLocation: Bool, error: LocationError?) {
		let isRealLocation = (configuration.locationType == .currentLocation) || (configuration.locationType == .unknown)

		let location: CLLocation?
		switch configuration.locationType {
		case .customLocation:
			location = configuration.location?.location
		default:
			guard SolsticeWidgetLocationManager.isAuthorized else {
				return (nil, isRealLocation, .notAuthorized)
			}
			
			location = await SolsticeWidgetLocationManager.shared.getLocation()
		}

		guard let location else {
			return (nil, isRealLocation, .locationUpdateFailed)
		}

		guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
			return (nil, isRealLocation, .reverseGeocodingFailed)
		}
		
		return (placemark, isRealLocation, nil)
	}

	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> Void) {
		Task {
			let (placemark, isRealLocation, error) = await fetchWidgetLocation(for: configuration)
			let widgetLocation = getLocation(for: placemark, isRealLocation: isRealLocation)
			let resolvedLocation = widgetLocation ?? (context.isPreview ? .proxiedToTimeZone : nil)
			let entry = SolsticeWidgetTimelineEntry(
				date: Date(),
				location: resolvedLocation,
				locationError: context.isPreview ? nil : error
			)
			completion(entry)
		}
	}

	func getTimeline(for configuration: Intent, in context: TimelineProviderContext, completion: @escaping (Timeline<Entry>) -> Void) {
		Task {
			let (placemark, isRealLocation, error) = await fetchWidgetLocation(for: configuration)
			let widgetLocation = getLocation(for: placemark, isRealLocation: isRealLocation)

			let currentDate = Date()
			let calendar = Calendar.current

			guard let coordinate = widgetLocation?.coordinate,
				  let todaySolar = Solar(for: currentDate, coordinate: coordinate) else {
				return completion(
					Timeline(
						entries: [
							SolsticeWidgetTimelineEntry(date: currentDate, location: widgetLocation, locationError: error)
						],
						policy: .after(.now.addingTimeInterval(60 * 15))
					)
				)
			}

			// Generate entries for today + next 2 days (3 days total)
			let daysToGenerate = 3
			var allKeyTimes: [Date] = [currentDate]
			var allHourlyTimes: [Date] = []
			var solarByDay: [Date: Solar] = [:]

			let today = calendar.startOfDay(for: currentDate)
			for dayOffset in 0..<daysToGenerate {
				guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: today),
					  let daySolar = Solar(for: dayDate, coordinate: coordinate) else {
					continue
				}

				let dayStart = calendar.startOfDay(for: dayDate)
				solarByDay[dayStart] = daySolar

				// Key times for this day
				var dayKeyTimes = [
					daySolar.safeSunrise.addingTimeInterval(-30 * 60),  // 30 min before sunrise
					daySolar.safeSunrise,
					daySolar.safeSunrise.addingTimeInterval(30 * 60),   // 30 min after sunrise
					daySolar.safeSunset.addingTimeInterval(-30 * 60),   // 30 min before sunset
					daySolar.safeSunset,
					daySolar.safeSunset.addingTimeInterval(30 * 60),    // 30 min after sunset
					dayDate.endOfDay
				]

				if let solarNoon = daySolar.solarNoon {
					dayKeyTimes.append(solarNoon)
				}

				allKeyTimes.append(contentsOf: dayKeyTimes)

				// Generate hourly times for this day
				let dayEndOfDay = dayDate.endOfDay
				var hourIter: Date

				if dayOffset == 0 {
					// For today, start from next hour boundary
					let comps = calendar.dateComponents([.year, .month, .day, .hour], from: currentDate)
					let hourStart = calendar.date(from: comps) ?? currentDate
					hourIter = hourStart < currentDate
						? (calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? currentDate)
						: hourStart
				} else {
					// For future days, start from midnight
					hourIter = dayStart
				}

				while hourIter <= dayEndOfDay {
					allHourlyTimes.append(hourIter)
					hourIter = hourIter.addingTimeInterval(60 * 60)
				}
			}

			// Filter to only future times
			allKeyTimes = allKeyTimes.filter { $0 >= currentDate }
			allHourlyTimes = allHourlyTimes.filter { $0 >= currentDate }

			// Filter out hourly times that are within 5 minutes of any key time
			let fiveMinutes: TimeInterval = 5 * 60
			let filteredHourlyTimes = allHourlyTimes.filter { hour in
				!allKeyTimes.contains { abs($0.timeIntervalSince(hour)) <= fiveMinutes }
			}

			// Helper to build an entry with relevance based on that day's solar data
			func makeEntry(at date: Date) -> Entry {
				let dayStart = calendar.startOfDay(for: date)
				let solar = solarByDay[dayStart] ?? todaySolar

				let distanceToSunrise = abs(date.distance(to: solar.safeSunrise))
				let distanceToSunset = abs(date.distance(to: solar.safeSunset))
				let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
				let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
					? .init(score: 10, duration: nearestEventDistance)
					: nil

				return Entry(
					date: date,
					location: widgetLocation,
					relevance: relevance
				)
			}

			// Create entries for key times and hourly times, then merge
			var mergedEntries: [Entry] = []
			for date in allKeyTimes { mergedEntries.append(makeEntry(at: date)) }
			for date in filteredHourlyTimes { mergedEntries.append(makeEntry(at: date)) }

			// Sort and dedupe entries less than 60 seconds apart
			let entries = mergedEntries
				.sorted { $0.date < $1.date }
				.reduce(into: [Entry]()) { result, entry in
					if let last = result.last, entry.date.timeIntervalSince(last.date) < 60 {
						return
					}

					result.append(entry)
				}

			// Refresh after the last entry, or after 3 days if no entries
			let lastEntryDate = entries.last?.date ?? currentDate
			return completion(Timeline(entries: entries, policy: .after(lastEntryDate)))
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
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36), location: .defaultLocation),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(1), location: nil),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(2), location: nil, locationError: .locationUpdateFailed),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(3), location: nil, locationError: .notAuthorized),
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(4), location: nil, locationError: .reverseGeocodingFailed),
		]
	}
	
	static var placeholder: Self {
		SolsticeWidgetTimelineEntry(date: .now, location: .proxiedToTimeZone)
	}
}
