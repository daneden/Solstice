//
//  AnyLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import Foundation
import CoreLocation
import SwiftData

protocol AnyLocation: Hashable {
	var title: String { get set }
	var subtitle: String? { get set }
	var timeZoneIdentifier: String? { get set }
	var latitude: Double { get }
	var longitude: Double { get }
}

extension AnyLocation {
	var timeZone: TimeZone {
		guard let timeZoneIdentifier,
					let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
			return .autoupdatingCurrent
		}
		
		return timeZone
	}
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	mutating func reverseGeocodeLocation() async {
		guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)),
					let placemark = placemarks.first else {
			return
		}
		
		title = placemark.name ?? title
		subtitle = placemark.country ?? subtitle
		timeZoneIdentifier = placemark.timeZone?.identifier ?? timeZoneIdentifier
	}
}

@Observable
class TemporaryLocation: AnyLocation {
	var title: String
	var subtitle: String?
	var timeZoneIdentifier: String?
	var latitude: Double = 0.0
	var longitude: Double = 0.0
	
	init(title: String, subtitle: String?, timeZoneIdentifier: String?, latitude: Double, longitude: Double) {
		self.title = title
		self.subtitle = subtitle
		self.timeZoneIdentifier = timeZoneIdentifier
		self.latitude = latitude
		self.longitude = longitude
	}
	
	func saveLocation(to context: ModelContext) throws -> UUID? {
		let savedLocation = SavedLocation(
			title: title,
			subtitle: subtitle,
			latitude: latitude,
			longitude: longitude,
			timeZoneIdentifier: timeZoneIdentifier
		)
		context.insert(savedLocation)
		try context.save()
		return savedLocation.uuid
	}
}

extension TemporaryLocation: Hashable, Equatable {
	static func == (lhs: TemporaryLocation, rhs: TemporaryLocation) -> Bool {
		lhs.hashValue == rhs.hashValue
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(latitude)
		hasher.combine(longitude)
	}
}


extension TemporaryLocation {
	static var placeholderLondon: TemporaryLocation {
		return TemporaryLocation(title: "London", subtitle: "England", timeZoneIdentifier: "GMT", latitude: 51.5072, longitude: -0.1276)
	}
	
	static var placeholderGreenland: TemporaryLocation {
		return TemporaryLocation(title: "Greenland", subtitle: nil, timeZoneIdentifier: "WGT", latitude: 74.7277, longitude: -41.3450)
	}
}

extension TemporaryLocation: Identifiable {
	var id: Int {
		hashValue
	}
}
