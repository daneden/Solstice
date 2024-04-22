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
	
	var timeZoneIdentifier: String?
	
	private(set) var location: CLLocation? {
		didSet {
			Task(priority: .high) {
				await processLocation(location)
			}
		}
	}
	
	private let locationManager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyReduced
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.first else { return }
		
		self.location = location
		
		locationManager.stopUpdatingLocation()
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
	func processLocation(_ location: CLLocation?) async {
		guard let location else { return }
		
		do {
			let reverseGeocoded = try await geocoder.reverseGeocodeLocation(location)
			if let firstResult = reverseGeocoded.first,
				 let resultTitle = firstResult.locality {
				withAnimation {
					title = resultTitle
					subtitle = firstResult.country
					timeZoneIdentifier = firstResult.timeZone?.identifier
				}
			}
		} catch {
			print(error)
		}
	}
	
	func requestLocation() async throws {
		guard isAuthorized else {
			return
		}
		
		locationManager.startUpdatingLocation()
		
//		for try await update in CLLocationUpdate.liveUpdates() {
//			await processLocation(update.location)
//			location = update.location
//			
//			if update.isStationary {
//				break
//			}
//		}
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
