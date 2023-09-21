//
//  SolsticeWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import CoreLocation
import Solar

fileprivate class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
	static let shared = LocationManagerDelegate()
	var didUpdateLocationsCallback: (_ locations: [CLLocation]) -> Void = { _ in }
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdateLocationsCallback(locations)
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
	fileprivate var locationManagerDelegate: LocationManagerDelegate {
		LocationManagerDelegate.shared
	}
	
	var locationManager: CLLocationManager {
		let manager = CLLocationManager()
		manager.desiredAccuracy = kCLLocationAccuracyReduced
		manager.delegate = locationManagerDelegate
		return manager
	}
	
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
	
	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> Void) {
		let isRealLocation = configuration.location == nil
		
		func processPlacemark(_ placemark: CLPlacemark) {
			let location = getLocation(for: placemark, isRealLocation: isRealLocation)
			
			let entry = SolsticeWidgetTimelineEntry(
				date: Date(),
				location: location
			)
			return completion(entry)
		}
		
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.first,
						error == nil else {
				return completion(SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
			}
			
			processPlacemark(placemark)
		}
		
		if let configurationLocation = configuration.location?.location ?? locationManager.location {
			geocoder.reverseGeocodeLocation(configurationLocation, completionHandler: handler)
		} else {
			locationManagerDelegate.didUpdateLocationsCallback = { locations in
				guard let location = locations.last else {
					return completion(SolsticeWidgetTimelineEntry(date: Date()))
				}
				
				geocoder.reverseGeocodeLocation(location, completionHandler: handler)
			}
			
			locationManager.requestLocation()
		}
	}
	
	func getTimeline(for configuration: Intent, in context: TimelineProviderContext, completion: @escaping (Timeline<Entry>) -> Void) {
		var entries: [Entry] = []
		let realLocation = configuration.location == nil
		
		func processPlacemark(_ placemark: CLPlacemark) {
			let currentDate = Date()
			let entryLimit = calendar.date(byAdding: .day, value: 1, to: currentDate)
			
			let widgetLocation = getLocation(for: placemark, isRealLocation: realLocation)
			
			var entryDate = currentDate
			while entryDate < entryLimit ?? currentDate.endOfDay {
				guard let solar = Solar(for: entryDate, coordinate: widgetLocation.coordinate) else {
					entryDate = entryDate.addingTimeInterval(60 * 30)
					continue
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
		
		let handler: CLGeocodeCompletionHandler = { placemarks, error in
			guard let placemark = placemarks?.first,
						error == nil else {
				return completion(Timeline(entries: [], policy: .atEnd))
			}
			
			processPlacemark(placemark)
		}
		
		if let location = configuration.location?.location ?? locationManager.location {
			geocoder.reverseGeocodeLocation(location, completionHandler: handler)
		} else {
			locationManagerDelegate.didUpdateLocationsCallback = { locations in
				guard let location = locations.last else {
					return completion(Timeline(entries: [SolsticeWidgetTimelineEntry(date: Date())], policy: .never))
				}
				
				geocoder.reverseGeocodeLocation(location, completionHandler: handler)
			}
			
			locationManager.requestLocation()
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
