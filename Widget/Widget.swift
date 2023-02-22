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

struct SolsticeWidgetTimelineProvider: IntentTimelineProvider {
	var currentLocation = CurrentLocation()
	
	func getLocation(for placemark: CLPlacemark, isRealLocation: Bool = false) -> SolsticeWidgetLocation {
		return SolsticeWidgetLocation(title: placemark.locality,
																	subtitle: placemark.country,
																	timeZoneIdentifier: placemark.timeZone?.identifier,
																	latitude: placemark.location?.coordinate.latitude ?? SolsticeWidgetLocation.defaultLocation.latitude,
																	longitude: placemark.location?.coordinate.longitude ?? SolsticeWidgetLocation.defaultLocation.longitude,
																	isRealLocation: isRealLocation)
	}
	
	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> Void) {
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.first,
						error == nil else {
				return completion(SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
			}
			
			let location = getLocation(for: placemark)
			let entry = SolsticeWidgetTimelineEntry(date: Date(), location: location)
			return completion(entry)
		}
		if let configurationLocation = configuration.location?.location {
			CLGeocoder().reverseGeocodeLocation(configurationLocation, completionHandler: handler)
		} else {
			currentLocation.requestLocation { location in
				CLGeocoder().reverseGeocodeLocation(location, completionHandler: handler)
			}
		}
	}
	
	func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SolsticeWidgetTimelineEntry>) -> Void) {
		var usingRealLocation = false
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.first,
						error == nil else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			let location = getLocation(for: placemark, isRealLocation: usingRealLocation)
			
			var entries: [SolsticeWidgetTimelineEntry] = []
			
			guard let solar = Solar(coordinate: location.coordinate) else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			let currentDate = Date()
			let distanceToSunrise = abs(currentDate.distance(to: solar.safeSunrise))
			let distanceToSunset = abs(currentDate.distance(to: solar.safeSunset))
			let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
			let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
			? .init(score: 10, duration: nearestEventDistance)
			: nil
			
			var nextUpdateDate = currentDate.addingTimeInterval(60 * 15)
			
			if nextUpdateDate < solar.safeSunrise {
				nextUpdateDate = solar.safeSunrise
			} else if nextUpdateDate < solar.safeSunset {
				nextUpdateDate = solar.safeSunset
			}
			
			entries.append(
				SolsticeWidgetTimelineEntry(
					date: currentDate,
					location: location,
					relevance: relevance
				)
			)
			
			let timeline = Timeline(
				entries: entries,
				policy: .after(nextUpdateDate)
			)
			
			completion(timeline)
		}
		
		if let configurationLocation = configuration.location?.location {
			CLGeocoder().reverseGeocodeLocation(configurationLocation, completionHandler: handler)
		} else {
			currentLocation.requestLocation { location in
				usingRealLocation = true
				CLGeocoder().reverseGeocodeLocation(location, completionHandler: handler)
			}
		}
	}
	
	typealias Entry = SolsticeWidgetTimelineEntry
	
	typealias Intent = ConfigurationIntent
	
	var widgetIdentifier: String?
	
	func placeholder(in context: Context) -> SolsticeWidgetTimelineEntry {
		SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation)
	}
}

struct SolsticeWidgetTimelineEntry: TimelineEntry {
	let date: Date
	var location: SolsticeWidgetLocation
	var relevance: TimelineEntryRelevance? = nil
}

struct SolsticeOverviewWidget: Widget {
	let kind: String = "OverviewWidget"
	
	@StateObject var locationManager = CurrentLocation()
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: kind,
			intent: ConfigurationIntent.self,
			provider: SolsticeWidgetTimelineProvider(widgetIdentifier: kind)
		) { timelineEntry in
			OverviewWidgetView(location: timelineEntry.location, entry: timelineEntry)
		}
		.configurationDisplayName("Daylight Today")
		.description("See today’s daylight length, how it compares to yesterday, and sunrise/sunset times.")
	}
}

struct SolsticeCountdownWidget: Widget {
	let kind: String = "CountdownWidget"
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: kind,
			intent: ConfigurationIntent.self,
			provider: SolsticeWidgetTimelineProvider(widgetIdentifier: kind)
		) { timelineEntry in
			let solar = Solar(for: timelineEntry.date, coordinate: timelineEntry.location.coordinate)!
			return CountdownWidgetView(solar: solar, timeZone: timelineEntry.location.timeZone)
		}
		.configurationDisplayName("Sunrise/Sunset Countdown")
		.description("See the time remaining until the next sunrise/sunset")
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

//struct Widget_Previews: PreviewProvider {
//    static var previews: some View {
//        WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
