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
	private(set) var place: ReverseGeocodedPlace?

	/// Mirrors `CLLocationManager.authorizationStatus`, which isn't observable:
	/// reading it straight off the manager registers no dependency, so views
	/// gating on it (like the sidebar's current-location row) never refresh when
	/// access is granted in System Settings.
	private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

	private(set) var location: CLLocation? {
		didSet {
			Task {
				await processLocation(location)
				await NotificationManager.scheduleNotifications(location: location)
				cacheLocationToAppGroup(location)
			}
		}
	}

	/// Caches the current location and reverse-geocoded place to the App Group for widget access
	private func cacheLocationToAppGroup(_ location: CLLocation?) {
		guard let location else { return }

		let locationData = LocationData(
			title: place?.city,
			subtitle: place?.country,
			latitude: location.coordinate.latitude,
			longitude: location.coordinate.longitude,
			timeZoneIdentifier: place?.timeZone?.identifier
		)

		LocationAppGroupCache.write(locationData)
	}

	@ObservationIgnored private let locationManager = CLLocationManager()

	@ObservationIgnored private var liveUpdatesTask: Task<Void, Never>?

	override init() {
		super.init()

		authorizationStatus = locationManager.authorizationStatus
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyReduced
	}

	func requestAccess() {
		#if os(macOS)
			// requestWhenInUseAuthorization() often no-ops on macOS. Iterating a
			// CLLocationUpdate stream is what makes the system present the prompt.
			startLiveUpdates()
		#else
			locationManager.requestWhenInUseAuthorization()
		#endif
	}

	func requestLocation() {
		guard isAuthorized else { return }
		startLiveUpdates()
	}

	/// Starts the long-lived location updates stream, at most once. Callers can
	/// invoke this freely (every scene activation does); without the guard each
	/// call would leak another never-ending stream iteration.
	private func startLiveUpdates() {
		guard liveUpdatesTask == nil else { return }
		liveUpdatesTask = Task {
			do {
				for try await update in CLLocationUpdate.liveUpdates() {
					if let updatedLocation = update.location {
						location = updatedLocation
					}
				}
			} catch {
				print("Error requesting location: \(error.localizedDescription)")
			}
			liveUpdatesTask = nil
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

		if let reverseGeocoded = await ReverseGeocoder.reverseGeocode(location) {
			place = reverseGeocoded
		}
	}

	var isAuthorized: Bool {
		switch authorizationStatus {
		case .authorizedAlways, .authorizedWhenInUse: return true
		default: return false
		}
	}

	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		authorizationStatus = manager.authorizationStatus
		if isAuthorized {
			startLiveUpdates()
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

	func locationManager(_: CLLocationManager, didFailWithError error: any Error) {
		print("Error with location manager delegate: \(error.localizedDescription)")
	}
}

extension CurrentLocation: ObservableLocation {
	var title: String? {
		place?.city
	}

	var subtitle: String? {
		place?.country
	}

	var timeZoneIdentifier: String? {
		place?.timeZone?.identifier
	}

	var latitude: Double {
		location?.coordinate.latitude ?? 0
	}

	var longitude: Double {
		location?.coordinate.longitude ?? 0
	}
}

extension CurrentLocation: Identifiable {
	static let identifier = "currentLocation"
	var id: String {
		CurrentLocation.identifier
	}
}
