//
//  SolsticeWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import CoreLocation
import SunKit

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation?
	var relevance: TimelineEntryRelevance?
	var locationError: LocationError?

	/// Pre-computed Sun for this entry's date and location (avoids recomputation in views)
	var cachedSun: Sun?
	/// Pre-computed tomorrow Sun for this entry (avoids recomputation in views)
	var cachedTomorrowSun: Sun?
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
			// Pre-compute Sun for snapshot
			var cachedSun: Sun?
			var cachedTomorrowSun: Sun?
			if let coord = resolvedLocation?.coordinate {
				let tz = resolvedLocation?.timeZone ?? .current
				cachedSun = Sun(for: Date(), coordinate: coord, timeZone: tz)
				cachedTomorrowSun = cachedSun?.tomorrow
			}
			let entry = SolsticeWidgetTimelineEntry(
				date: Date(),
				location: resolvedLocation,
				locationError: context.isPreview ? nil : error,
				cachedSun: cachedSun,
				cachedTomorrowSun: cachedTomorrowSun
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

			guard let coordinate = widgetLocation?.coordinate else {
				return completion(
					Timeline(
						entries: [
							SolsticeWidgetTimelineEntry(date: currentDate, location: widgetLocation, locationError: error, cachedSun: nil, cachedTomorrowSun: nil)
						],
						policy: .after(.now.addingTimeInterval(60 * 15))
					)
				)
			}

			let timeZone = widgetLocation?.timeZone ?? .current
			let todaySun = Sun(for: currentDate, coordinate: coordinate, timeZone: timeZone)

			// Generate entries for today + next 2 days (3 days total)
			let daysToGenerate = 3
			var allKeyTimes: [Date] = [currentDate]
			var allHourlyTimes: [Date] = []
			var sunByDay: [Date: Sun] = [:]

			let today = calendar.startOfDay(for: currentDate)
			for dayOffset in 0..<daysToGenerate {
				guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
					continue
				}

				let daySun = Sun(for: dayDate, coordinate: coordinate, timeZone: timeZone)
				let dayStart = calendar.startOfDay(for: dayDate)
				sunByDay[dayStart] = daySun

				// Key times for this day
				var dayKeyTimes = [
					daySun.safeSunrise.addingTimeInterval(-30 * 60),  // 30 min before sunrise
					daySun.safeSunrise,
					daySun.safeSunrise.addingTimeInterval(30 * 60),   // 30 min after sunrise
					daySun.safeSunset.addingTimeInterval(-30 * 60),   // 30 min before sunset
					daySun.safeSunset,
					daySun.safeSunset.addingTimeInterval(30 * 60),    // 30 min after sunset
					dayDate.endOfDay
				]

				dayKeyTimes.append(daySun.solarNoon)

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
				var sun = sunByDay[dayStart] ?? todaySun

				// Update the sun's date to the entry time (reuses cached calculations if same day)
				sun.setDate(date)

				let distanceToSunrise = abs(sun.safeSunrise.timeIntervalSince(date))
				let distanceToSunset = abs(sun.safeSunset.timeIntervalSince(date))
				let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
				let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
					? .init(score: 10, duration: nearestEventDistance)
					: nil

				// Pre-compute tomorrow sun for widgets that need it
				let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
				let tomorrowSun = sunByDay[tomorrowStart] ?? sun.tomorrow

				return Entry(
					date: date,
					location: widgetLocation,
					relevance: relevance,
					cachedSun: sun,
					cachedTomorrowSun: tomorrowSun
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
		let sun = Sun(for: Date(), coordinate: SolsticeWidgetLocation.defaultLocation.coordinate, timeZone: SolsticeWidgetLocation.defaultLocation.timeZone)
		return SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation, cachedSun: sun, cachedTomorrowSun: sun.tomorrow)
	}
}

extension SolsticeWidgetTimelineEntry {
	/// Helper to create an entry with pre-computed Sun
	static func withSun(date: Date, location: SolsticeWidgetLocation?, locationError: LocationError? = nil) -> SolsticeWidgetTimelineEntry {
		guard let loc = location else {
			return SolsticeWidgetTimelineEntry(date: date, location: nil, locationError: locationError, cachedSun: nil, cachedTomorrowSun: nil)
		}
		let sun = Sun(for: date, coordinate: loc.coordinate, timeZone: loc.timeZone)
		return SolsticeWidgetTimelineEntry(date: date, location: loc, locationError: locationError, cachedSun: sun, cachedTomorrowSun: sun.tomorrow)
	}

	static func previewTimeline() async -> [SolsticeWidgetTimelineEntry] {
		[
		.withSun(date: .now, location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 6), location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 12), location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 18), location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 24), location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 30), location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 36), location: .defaultLocation),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(1), location: nil),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(2), location: nil, locationError: .locationUpdateFailed),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(3), location: nil, locationError: .notAuthorized),
		.withSun(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(4), location: nil, locationError: .reverseGeocodingFailed),
		]
	}

	static var placeholder: Self {
		.withSun(date: .now, location: .proxiedToTimeZone)
	}
}
