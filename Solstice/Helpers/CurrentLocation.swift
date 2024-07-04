//
//  CurrentLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2022.
//

import CoreLocation
import SwiftUI
import Combine

#if canImport(WidgetKit)
import WidgetKit
#endif

class CurrentLocation: NSObject, ObservableObject, ObservableLocation, Identifiable {
	static let identifier = "currentLocation"
	@AppStorage(Preferences.cachedLatitude) var latitude
	@AppStorage(Preferences.cachedLongitude) var longitude
	
	@Published var title: String?
	@Published var subtitle: String?
	let id = CurrentLocation.identifier
	
	@Published private(set) var placemark: CLPlacemark?
	
	@Published var timeZoneIdentifier: String?
	
	private(set) var location: CLLocation? {
		didSet {
			Task { await processLocation(location) }
		}
	}
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	private var sink: AnyCancellable? = nil
	
	override init() {
		super.init()
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyReduced
		
		sink = locationManager.publisher(for: \.location).sink { location in
			self.location = location
		}
	}
	
	func requestAccess() {
#if os(macOS)
		self.locationManager.requestAlwaysAuthorization()
#else
		self.locationManager.requestWhenInUseAuthorization()
#endif
	}
}

// MARK: Location update request methods and handlers
extension CurrentLocation {
	@MainActor func processLocation(_ location: CLLocation?) async -> Void {
		guard let location else { return }
		
		latitude = location.coordinate.latitude
		longitude = location.coordinate.longitude
		
		let reverseGeocoded = try? await geocoder.reverseGeocodeLocation(location)
		if let firstResult = reverseGeocoded?.first {
			placemark = firstResult
			title = firstResult.locality
			subtitle = firstResult.country
			timeZoneIdentifier = firstResult.timeZone?.identifier
		}
	}
	
	@available(iOS 17, watchOS 10, macOS 14, visionOS 2, *)
	func requestLocation() async {
		do {
			for try await update in CLLocationUpdate.liveUpdates() {
				guard let location = update.location else { return }
				
				guard let storedLocation = self.location else {
					return self.location = location
				}
				
				if storedLocation.distance(from: location) > 10000 {
					return self.location = location
				}
			}
		} catch {
			print(error.localizedDescription)
		}
	}
	
	func requestLocation() {
		if #available(iOS 17, watchOS 10, macOS 14, visionOS 2, *) {
			Task {
				await requestLocation()
			}
		} else {
			locationManager.requestLocation()
			locationManager.startUpdatingLocation()
			
#if !os(watchOS) && !os(visionOS)
			locationManager.startMonitoringSignificantLocationChanges()
#endif
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
	
	var isAuthorizedForWidgetUpdates: Bool {
#if !os(watchOS)
		locationManager.isAuthorizedForWidgetUpdates
#else
		isAuthorized
#endif
	}
}

extension CurrentLocation: CLLocationManagerDelegate {
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
#if canImport(WidgetKit)
		WidgetCenter.shared.reloadAllTimelines()
#endif
		
		if isAuthorized { requestLocation() }
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("Received location update")
		
		let newLocation = locations.last
		
		if location == nil {
			updateLocation(newLocation)
		} else if let newLocation, let location,
							newLocation.distance(from: location) > CLLocationDistance(10_000) {
			updateLocation(newLocation)
		} else {
			print("Location is within 10km of last update")
		}
	}
	
	private func updateLocation(_ newLocation: CLLocation?) {
		self.location = newLocation
		
		if newLocation != nil {
			Task { await NotificationManager.scheduleNotifications(currentLocation: self) }
			
#if canImport(WidgetKit)
			WidgetCenter.shared.reloadAllTimelines()
#endif
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
	}
}
