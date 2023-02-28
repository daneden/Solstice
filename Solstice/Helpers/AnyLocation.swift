//
//  AnyLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import Foundation
import CoreLocation
import CoreData

protocol AnyLocation {
	var title: String? { get }
	var subtitle: String? { get }
	var timeZoneIdentifier: String? { get }
	var latitude: Double { get }
	var longitude: Double { get }
}

protocol ObservableLocation: AnyLocation, ObservableObject { }

extension AnyLocation {
	var timeZone: TimeZone {
		guard let timeZoneIdentifier,
					let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
			return .autoupdatingCurrent
		}
		
		return timeZone
	}
	
	var coordinate: CLLocation {
		CLLocation(latitude: latitude, longitude: longitude)
	}
}

extension SavedLocation: ObservableLocation { }

class TemporaryLocation: ObservableLocation {
	@Published var title: String?
	@Published var subtitle: String?
	@Published var timeZoneIdentifier: String?
	@Published var latitude: Double = 0.0
	@Published var longitude: Double = 0.0
	
	init(title: String?, subtitle: String?, timeZoneIdentifier: String?, latitude: Double, longitude: Double) {
		self.title = title
		self.subtitle = subtitle
		self.timeZoneIdentifier = timeZoneIdentifier
		self.latitude = latitude
		self.longitude = longitude
	}
	
	func saveLocation(to context: NSManagedObjectContext) throws -> SavedLocation.ID {
		let savedLocation = SavedLocation(context: context)
		savedLocation.title = title
		savedLocation.subtitle = subtitle
		savedLocation.timeZoneIdentifier = timeZoneIdentifier
		savedLocation.longitude = longitude
		savedLocation.latitude = latitude

		try context.save()
		return savedLocation.id
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
