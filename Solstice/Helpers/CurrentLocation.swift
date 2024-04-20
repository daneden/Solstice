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

@Observable
class CurrentLocation: NSObject, ObservableLocation, Identifiable {
	var title: String = "My Location"
	var subtitle: String?
	let id = "currentLocation"
	
	var latitude: Double { coordinate.latitude }
	var longitude: Double { coordinate.longitude }
	
	private(set) var placemark: CLPlacemark?
	
	var timeZoneIdentifier: String?
	
	private(set) var location: CLLocation? {
		didSet {
			Task { await processLocation(location) }
		}
	}
	
	var coordinate: CLLocationCoordinate2D {
		location?.coordinate ?? .init()
	}
	
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	override init() {
		super.init()
		self.locationManager.delegate = self
	}
	
	func requestAccess() {
		#if os(macOS)
		locationManager.requestAlwaysAuthorization()
		#else
		locationManager.requestWhenInUseAuthorization()
		#endif
	}
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
		for try await locationUpdate in CLLocationUpdate.liveUpdates() {
			self.location = locationUpdate.location
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
	
}
