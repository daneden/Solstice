//
//  CurrentLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2022.
//

import CoreLocation
import SwiftUI

#if canImport(WidgetKit)
import WidgetKit
#endif

@Observable
class CurrentLocation: NSObject, CLLocationManagerDelegate, Identifiable {
	var title: String = "My Location"
	var subtitle: String?
	let id = "currentLocation"
	
	private(set) var placemark: CLPlacemark?
	
	var timeZoneIdentifier: String?
	
	private(set) var location: CLLocation?
	
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	override init() {
		super.init()
		self.locationManager.delegate = self
		self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
		self.locationManager.startUpdatingLocation()
	}
	
	func requestAccess() {
		#if os(macOS)
		locationManager.requestAlwaysAuthorization()
		#else
		locationManager.requestWhenInUseAuthorization()
		#endif
	}
}

extension CurrentLocation: AnyLocation {
	var coordinate: CLLocationCoordinate2D {
		location?.coordinate ?? .init()
	}
	
	var latitude: Double { coordinate.latitude }
	var longitude: Double { coordinate.longitude }
}

// MARK: Location update request methods and handlers
extension CurrentLocation {
	@MainActor func processLocation(_ location: CLLocation?) async -> Void {
		guard let location else { return }
		
		let reverseGeocoded = try? await geocoder.reverseGeocodeLocation(location)
		if let firstResult = reverseGeocoded?.first,
			 let resultTitle = firstResult.locality {
			withAnimation {
				placemark = firstResult
				title = resultTitle
				subtitle = firstResult.country
				timeZoneIdentifier = firstResult.timeZone?.identifier
			}
		}
	}
	
	func requestLocation() async throws {
		print("requesting location")
		
		requestAccess()
		
		for try await update in CLLocationUpdate.liveUpdates() {
			self.location = update.location
			// await processLocation(update.location)
			
			if update.isStationary {
				break
			}
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
