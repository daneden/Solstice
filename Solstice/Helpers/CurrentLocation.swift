//
//  CurrentLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2022.
//

import Foundation
import CoreLocation

protocol AnyLocation: ObservableObject {
	var title: String? { get }
	var subtitle: String? { get }
	var timeZoneIdentifier: String? { get }
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
}

class CurrentLocation: NSObject, ObservableObject, AnyLocation {
	@Published private(set) var title: String?
	@Published private(set) var subtitle: String?
	@Published private(set) var latitude: Double = 0
	@Published private(set) var longitude: Double = 0
	@Published private(set) var timeZoneIdentifier: String?
	
	static let shared = CurrentLocation()
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.requestWhenInUseAuthorization()
		#if !os(watchOS)
		locationManager.startMonitoringSignificantLocationChanges()
		#endif
	}
}

extension CurrentLocation: CLLocationManagerDelegate {
	@MainActor
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = locations.first {
			latitude = location.coordinate.latitude
			longitude = location.coordinate.longitude
			
			Task {
				let reverseGeocoded = try? await geocoder.reverseGeocodeLocation(location)
				if let firstResult = reverseGeocoded?.first {
					title = firstResult.locality
					subtitle = firstResult.country
					timeZoneIdentifier = firstResult.timeZone?.identifier
				}
			}
		}
	}
	
	var isAuthorized: Bool {
		switch locationManager.authorizationStatus {
		case .authorizedAlways, .authorizedWhenInUse: return true
		default: return false
		}
	}
}

extension SavedLocation: AnyLocation {
	
}
