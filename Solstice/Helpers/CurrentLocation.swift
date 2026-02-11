//
//  CurrentLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2022.
//

import CoreLocation
import SwiftUI

@Observable
class CurrentLocation: NSObject, CLLocationManagerDelegate {
	private(set) var placemark: CLPlacemark?
	
	private(set) var location: CLLocation? {
		didSet {
			Task {
				await processLocation(location)
				await NotificationManager.scheduleNotifications(location: location)
				cacheLocationToAppGroup(location)
			}
		}
	}

	/// Caches the current location and placemark to the App Group for widget access
	private func cacheLocationToAppGroup(_ location: CLLocation?) {
		guard let location else { return }

		let locationData = LocationData(
			title: placemark?.locality,
			subtitle: placemark?.country,
			latitude: location.coordinate.latitude,
			longitude: location.coordinate.longitude,
			timeZoneIdentifier: placemark?.timeZone?.identifier
		)

		LocationAppGroupCache.write(locationData)
	}
	
	@ObservationIgnored private let locationManager = CLLocationManager()
	@ObservationIgnored private let geocoder = CLGeocoder()
	
	override init() {
		super.init()

		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyReduced
	}
	
	func requestAccess() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	func requestLocation() {
		guard isAuthorized else { return }
		Task {
			do {
				try await requestLocationFromLiveUpdates()
			} catch {
				print("Error requesting location: \(error.localizedDescription)")
			}
		}
	}
	
	func requestLocationFromLiveUpdates() async throws {
		let updates = CLLocationUpdate.liveUpdates()
		for try await update in updates {
			self.location = update.location
		}
	}

	/// Fetches a single location update and returns it
	/// Useful for background tasks where we need to await a location
	static func fetchCurrentLocation() async throws -> CLLocation {
		let updates = CLLocationUpdate.liveUpdates()
		for try await update in updates {
			if let location = update.location {
				return location
			}
		}
		throw CLError(.locationUnknown)
	}
}

// MARK: Location update request methods and handlers
extension CurrentLocation {
	@MainActor func processLocation(_ location: CLLocation?) async {
		guard let location else { return }
		
		let reverseGeocoded = try? await geocoder.reverseGeocodeLocation(location)
		if let firstResult = reverseGeocoded?.first {
			placemark = firstResult
		}
	}
	
	var authorizationStatus: CLAuthorizationStatus {
		locationManager.authorizationStatus
	}
	
	var isAuthorized: Bool {
		switch authorizationStatus {
		case .authorizedAlways, .authorizedWhenInUse: return true
		default: return false
		}
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if location == nil && isAuthorized {
			Task {
				do {
					try await requestLocationFromLiveUpdates()
				} catch {
					requestLocation()
				}
			}
		}
	}
}

extension CurrentLocation {
	// MARK: Fallback location request code
	func legacyRequestLocation() {
		locationManager.startUpdatingLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		self.location = location
		manager.stopUpdatingLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
		print("Error with location manager delegate: \(error.localizedDescription)")
	}
}

extension CurrentLocation: ObservableLocation {
	var title: String? { placemark?.locality }
	var subtitle: String? { placemark?.country }
	var timeZoneIdentifier: String? { placemark?.timeZone?.identifier }
	var latitude: Double { location?.coordinate.latitude ?? 0 }
	var longitude: Double { location?.coordinate.longitude ?? 0 }
}

extension CurrentLocation: Identifiable {
	static let identifier = "currentLocation"
	var id: String { CurrentLocation.identifier }
}
