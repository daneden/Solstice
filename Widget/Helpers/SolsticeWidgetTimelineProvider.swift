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
	var location: SolsticeWidgetLocation
	var relevance: TimelineEntryRelevance? = nil
	var prefersGraphicalAppearance = false
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
			guard let placemark = placemarks?.first,
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
		
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			let currentDate = Date()
			let entryLimit = calendar.date(byAdding: .day, value: 1, to: currentDate)
			guard let placemark = placemarks?.first,
						error == nil else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			let widgetLocation = getLocation(for: placemark, isRealLocation: realLocation)
			
			var entryDate = currentDate
			while entryDate < entryLimit ?? currentDate.endOfDay {
				guard let solar = Solar(for: entryDate, coordinate: widgetLocation.coordinate) else {
					return completion(Timeline(entries: entries, policy: .atEnd))
				}
				
				let distanceToSunrise = abs(entryDate.distance(to: solar.safeSunrise))
				let distanceToSunset = abs(entryDate.distance(to: solar.safeSunset))
				let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
				let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
				? .init(score: 10, duration: nearestEventDistance)
				: nil
				
				#if os(macOS)
				let prefersGraphicalAppearance = false
				#else
				let prefersGraphicalAppearance = (configuration.rectangularWidgetDisplaysChart as? Bool == true) && context.family == .accessoryRectangular
				#endif
				
				entries.append(
					SolsticeWidgetTimelineEntry(
						date: entryDate,
						location: widgetLocation,
						relevance: relevance,
						prefersGraphicalAppearance: prefersGraphicalAppearance
					)
				)
				
				entryDate = entryDate.addingTimeInterval(60 * 15)
			}
			
			let solar = Solar(for: currentDate, coordinate: widgetLocation.coordinate)
			
			if let solar {
				if currentDate < solar.safeSunrise {
					entries.append(SolsticeWidgetTimelineEntry(date: solar.safeSunrise.addingTimeInterval(1), location: widgetLocation))
				}
				
				if currentDate < solar.safeSunset {
					entries.append(SolsticeWidgetTimelineEntry(date: solar.safeSunset.addingTimeInterval(1), location: widgetLocation))
				}
			}
			
			entries = entries.sorted(by: { lhs, rhs in
				lhs.date.compare(rhs.date) == .orderedAscending
			})
			
			completion(Timeline(entries: entries, policy: .after(solar?.nextSolarEvent?.date ?? currentDate.endOfDay)))
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

