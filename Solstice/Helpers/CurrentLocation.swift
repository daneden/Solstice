//
//  CurrentLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2022.
//

import Foundation
import CoreLocation
import SwiftUI

#if canImport(WidgetKit)
import WidgetKit
#endif

class CurrentLocation: NSObject, ObservableObject, ObservableLocation, Identifiable {
	@AppStorage(Preferences.cachedLatitude) private var cachedLatitude
	@AppStorage(Preferences.cachedLongitude) private var cachedLongitude
	
	@Published var title: String?
	@Published var subtitle: String?
	let id = "currentLocation"
	
	@Published private(set) var placemark: CLPlacemark?
	
	@Published private(set) var latitude: Double = 0 {
		didSet {
			cachedLatitude = latitude
		}
	}
	
	@Published private(set) var longitude: Double = 0 {
		didSet {
			cachedLongitude = longitude
		}
	}
	
	@Published var timeZoneIdentifier: String?
	@Published private(set) var latestLocation: CLLocation?
	private var didUpdateLocationsCallback: ((CLLocation?) -> Void)?
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	static let shared = CurrentLocation()
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	override init() {
		super.init()

		latitude = cachedLatitude
		longitude = cachedLongitude
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyReduced
		latestLocation = locationManager.location ?? CLLocation(latitude: latitude, longitude: longitude)
	}
	
	func requestAccess() {
		self.locationManager.requestWhenInUseAuthorization()
	}
}

extension CurrentLocation: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("Received location update")
		
		if didUpdateLocationsCallback != nil {
			didUpdateLocationsCallback?(locations.last)
			didUpdateLocationsCallback = nil
		} else {
			Task {
				await defaultDidUpdateLocationsCallback(locations)
				await NotificationManager.scheduleNotifications(locationManager: self)
			}
		}
		
		#if canImport(WidgetKit)
		WidgetCenter.shared.reloadAllTimelines()
		#endif
	}
	
	@MainActor
	func defaultDidUpdateLocationsCallback(_ locations: [CLLocation]) async -> Void {
		if let location = locations.last {
			latestLocation = location
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
		
		locationManager.stopUpdatingLocation()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		#if canImport(WidgetKit)
		WidgetCenter.shared.reloadAllTimelines()
		#endif
		
		if CurrentLocation.isAuthorized {
			self.locationManager.requestLocation()
		}
	}
	
	func requestLocation(handler: @escaping (CLLocation?) -> Void) {
		self.didUpdateLocationsCallback = handler
		requestLocation()
		return
	}
	
	func requestLocation() {
		locationManager.requestLocation()
		locationManager.startUpdatingLocation()
		#if !os(watchOS)
		locationManager.startMonitoringSignificantLocationChanges()
		#endif
	}
	
	static var authorizationStatus: CLAuthorizationStatus {
		CLLocationManager().authorizationStatus
	}
	
	static var isAuthorized: Bool {
		switch authorizationStatus {
		case .authorizedAlways, .authorizedWhenInUse: return true
		default: return false
		}
	}
	
	var isAuthorizedForWidgetUpdates: Bool {
		#if !os(watchOS)
		locationManager.isAuthorizedForWidgetUpdates
		#else
		CurrentLocation.isAuthorized
		#endif
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
	}
}
