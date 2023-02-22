//
//  CurrentLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2022.
//

import Foundation
import CoreLocation

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
}

class CurrentLocation: NSObject, ObservableObject, ObservableLocation {
	@Published private(set) var title: String?
	@Published private(set) var subtitle: String?
	@Published private(set) var latitude: Double = 0
	@Published private(set) var longitude: Double = 0
	@Published private(set) var timeZoneIdentifier: String?
	private var didUpdateLocationsCallback: ((CLLocation) -> Void)?
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	static let shared = CurrentLocation()
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	override init() {
		super.init()

		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyReduced
		
		if self.locationManager.authorizationStatus == .notDetermined {
			self.locationManager.requestWhenInUseAuthorization()
		}
		
#if os(watchOS)
		self.locationManager.startUpdatingLocation()
#else
		self.locationManager.startMonitoringSignificantLocationChanges()
#endif
	}
}

extension CurrentLocation: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdateLocationsCallback?(locations.first!)
		
		Task {
			await defaultDidUpdateLocationsCallback(locations)
		}
	}
	
	@MainActor
	func defaultDidUpdateLocationsCallback(_ locations: [CLLocation]) -> Void {
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
	
	func requestLocation(handler: @escaping (CLLocation) -> Void) {
		self.didUpdateLocationsCallback = handler
		return locationManager.requestLocation()
	}
	
	var isAuthorized: Bool {
		switch locationManager.authorizationStatus {
		case .authorizedAlways, .authorizedWhenInUse: return true
		default: return false
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
	}
}

extension SavedLocation: ObservableLocation { }
