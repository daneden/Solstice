//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 19/02/2023.
//

import WidgetKit
import SwiftUI
import Intents
import Solar

enum SolsticeWidgetKind: String {
	case CountdownWidget, OverviewWidget
}

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation
	var relevance: TimelineEntryRelevance? = nil
}

struct SolsticeOverviewWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	internal let currentLocation = CurrentLocation()
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Overview")
		]
	}
}

struct SolsticeCountdownWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	internal let currentLocation = CurrentLocation()
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Countdown")
		]
	}
}

protocol SolsticeWidgetTimelineProvider: IntentTimelineProvider where Entry == SolsticeWidgetTimelineEntry, Intent == ConfigurationIntent {
	var currentLocation: CurrentLocation { get }
	var geocoder: CLGeocoder { get }
}

extension SolsticeWidgetTimelineProvider {
	func getLocation(for placemark: CLPlacemark? = nil, isRealLocation: Bool = false) -> SolsticeWidgetLocation {
		return SolsticeWidgetLocation(title: placemark?.locality,
																	subtitle: placemark?.country,
																	timeZoneIdentifier: placemark?.timeZone?.identifier,
																	latitude: placemark?.location?.coordinate.latitude ?? currentLocation.latestLocation?.coordinate.latitude ?? SolsticeWidgetLocation.defaultLocation.latitude,
																	longitude: placemark?.location?.coordinate.longitude ?? currentLocation.latestLocation?.coordinate.longitude ?? SolsticeWidgetLocation.defaultLocation.longitude,
																	isRealLocation: isRealLocation)
	}
	
	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> Void) {
		let isRealLocation = configuration.location == nil
		
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.last,
						error == nil else {
				return completion(SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
			}
			
			let location = getLocation(for: placemark, isRealLocation: isRealLocation)
			let entry = SolsticeWidgetTimelineEntry(date: Date(), location: location)
			return completion(entry)
		}
		
		if let configurationLocation = configuration.location?.location ?? currentLocation.latestLocation {
			geocoder.reverseGeocodeLocation(configurationLocation, completionHandler: handler)
		} else {
			currentLocation.requestLocation { location in
				guard let location else { return }
				geocoder.reverseGeocodeLocation(location, completionHandler: handler)
			}
		}
	}
	
	func getTimeline(for configuration: Intent, in context: TimelineProviderContext, completion: @escaping (Timeline<Entry>) -> Void) {
		var entries: [Entry] = []
		let realLocation = configuration.location == nil
		
		let handler: CLGeocodeCompletionHandler = { placemarks, _ in
			guard let placemark = placemarks?.first else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			let widgetLocation = getLocation(for: placemark, isRealLocation: realLocation)
			
			
			var entryDate = Date()
			while entryDate < .now.endOfDay {
				guard let solar = Solar(for: entryDate, coordinate: widgetLocation.coordinate) else {
					return completion(Timeline(entries: entries, policy: .atEnd))
				}
				
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
				
				entryDate = entryDate.addingTimeInterval(60 * 30)
			}
			
			completion(Timeline(entries: entries, policy: .atEnd))
		}
		
		if let location = configuration.location?.location ?? currentLocation.latestLocation {
			geocoder.reverseGeocodeLocation(location, completionHandler: handler)
		} else {
			currentLocation.requestLocation { location in
				guard let location else { return completion(Timeline(entries: [], policy: .atEnd)) }
				geocoder.reverseGeocodeLocation(location, completionHandler: handler)
			}
		}
	}
	
	func placeholder(in context: Context) -> SolsticeWidgetTimelineEntry {
		SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation)
	}
}
