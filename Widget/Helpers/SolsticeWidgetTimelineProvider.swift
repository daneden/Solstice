//
//  SolsticeWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import CoreLocation
import CoreData
import AppIntents
import SwiftUI

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation?
	var relevance: TimelineEntryRelevance?
	var locationError: LocationError?
}

enum LocationError: Error {
	case notAuthorized, locationUpdateFailed, reverseGeocodingFailed
	/// Widget was configured with the old intent system and lost its custom location data during migration
	case needsReconfiguration
}

struct SolsticeTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = SolsticeWidgetTimelineEntry
	typealias Intent = SolsticeConfigurationIntent

	let widgetKind: SolsticeWidgetKind
	private let geocoder = CLGeocoder()

	func recommendations() -> [AppIntentRecommendation<Intent>] {
		// Provide recommendations based on saved locations
		let context = PersistenceController.shared.container.viewContext
		let request = SavedLocation.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)]
		
		let currentLocationRecommendation = AppIntentRecommendation(
			intent: Intent(selectedLocation: .currentLocation),
			description: String(localized: "Current Location")
		)

		guard let savedLocations = try? context.fetch(request) else {
			return [currentLocationRecommendation]
		}

		let savedLocationRecommendations = savedLocations.compactMap { savedLocation -> AppIntentRecommendation<Intent>? in
			let entity = LocationAppEntity(from: savedLocation)
			let intent = Intent(selectedLocation: entity)
			return AppIntentRecommendation(
				intent: intent,
				description: Text(savedLocation.title ?? "Location")
			)
		}

		return [currentLocationRecommendation] + savedLocationRecommendations
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

	/// Creates a SolsticeWidgetLocation from a LocationAppEntity
	private func getLocation(from entity: LocationAppEntity) -> SolsticeWidgetLocation {
		SolsticeWidgetLocation(
			title: entity.title,
			subtitle: entity.subtitle,
			timeZoneIdentifier: entity.timeZoneIdentifier,
			latitude: entity.latitude,
			longitude: entity.longitude,
			isRealLocation: false,
			locationUUID: entity.savedLocationUUID
		)
	}

	/// Fetches the widget location based on the configuration
	private func fetchWidgetLocation(for configuration: Intent) async -> (location: SolsticeWidgetLocation?, isRealLocation: Bool, error: LocationError?) {
		// Check if this is a legacy widget that lost its custom location data during migration
		if configuration.needsReconfiguration {
			return (nil, false, .needsReconfiguration)
		}

		let locationEntity = configuration.resolvedLocation

		// If a specific location is selected (not current location), use it
		if !locationEntity.isCurrentLocation {
			var widgetLocation = getLocation(from: locationEntity)

			// For legacy migrations, the timezone might be missing - fetch it if needed
			if configuration.needsTimezoneResolution || widgetLocation.timeZoneIdentifier == nil {
				let location = CLLocation(latitude: locationEntity.latitude, longitude: locationEntity.longitude)
				if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
					widgetLocation.timeZoneIdentifier = placemark.timeZone?.identifier
				}
			}

			return (widgetLocation, false, nil)
		}

		// Use current location
		guard SolsticeWidgetLocationManager.isAuthorized else {
			return (nil, true, .notAuthorized)
		}

		guard let currentLocation = await SolsticeWidgetLocationManager.shared.getLocation() else {
			return (nil, true, .locationUpdateFailed)
		}

		// Reverse geocode to get timezone for current location
		guard let placemark = try? await geocoder.reverseGeocodeLocation(currentLocation).first else {
			return (nil, true, .reverseGeocodingFailed)
		}

		return (getLocation(for: placemark, isRealLocation: true), true, nil)
	}

	func snapshot(for configuration: Intent, in context: Context) async -> SolsticeWidgetTimelineEntry {
		let (widgetLocation, _, error) = await fetchWidgetLocation(for: configuration)
		let resolvedLocation = widgetLocation ?? (context.isPreview ? .proxiedToTimeZone : nil)
		let entry = SolsticeWidgetTimelineEntry(
			date: Date(),
			location: resolvedLocation,
			locationError: context.isPreview ? nil : error
		)

		return entry
	}

	func timeline(for configuration: SolsticeConfigurationIntent, in context: Context) async -> Timeline<SolsticeWidgetTimelineEntry> {
		let (widgetLocation, _, error) = await fetchWidgetLocation(for: configuration)
		
		let currentDate = Date()
		let calendar = Calendar.current
		
		guard let coordinate = widgetLocation?.coordinate,
					let todaySolar = NTSolar(for: currentDate, coordinate: coordinate, timeZone: widgetLocation?.timeZone ?? .autoupdatingCurrent) else {
			return Timeline(
				entries: [
					SolsticeWidgetTimelineEntry(date: currentDate, location: widgetLocation, locationError: error)
				],
				policy: .after(.now.addingTimeInterval(60 * 15))
			)
		}
		
		#if os(watchOS)
		let daysToGenerate = 1
		#else
		let daysToGenerate = 3
		#endif
		var allKeyTimes: [Date] = [currentDate]
		var allHourlyTimes: [Date] = []
		var solarByDay: [Date: NTSolar] = [:]
		
		let today = calendar.startOfDay(for: currentDate)
		for dayOffset in 0..<daysToGenerate {
			guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: today),
						let daySolar = NTSolar(for: dayDate, coordinate: coordinate, timeZone: widgetLocation?.timeZone ?? .autoupdatingCurrent) else {
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
		return Timeline(entries: entries, policy: .after(lastEntryDate))
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
		SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36).addingTimeInterval(5), location: nil, locationError: .needsReconfiguration),
		]
	}
	
	static var placeholder: Self {
		SolsticeWidgetTimelineEntry(date: .now, location: .proxiedToTimeZone)
	}
}
