//
//  SolsticeWidgetLocationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 20/01/2026.
//
import Foundation
import CoreLocation

actor SolsticeWidgetLocationManager {
	static let shared = SolsticeWidgetLocationManager()

	private var cachedLocation: CLLocation?
	private var cacheTimestamp: Date?
	private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

	private var cachedLocationData: LocationData?
	private var cachedLocationDataCoordinate: CLLocation?
	private let geocoder = CLGeocoder()
	private let significantDistanceChange: CLLocationDistance = 500
	
	static var isAuthorized: Bool {
		#if os(watchOS)
		[.authorizedAlways, .authorizedWhenInUse].contains(CLLocationManager().authorizationStatus)
		#else
		CLLocationManager().isAuthorizedForWidgetUpdates
		#endif
	}

	/// Returns cached location if valid, otherwise fetches a new one
	func getLocation() async -> CLLocation? {
		// First, check the in-memory cache
		if let cachedLocation,
		   let cacheTimestamp,
		   Date().timeIntervalSince(cacheTimestamp) < cacheValidityDuration {
			return cachedLocation
		}

		// Second, check the shared App Group cache from the main app
		if let (sharedLocation, sharedLocationData) = getSharedAppGroupData() {
			cachedLocation = sharedLocation
			cacheTimestamp = Date()
			// Also use the location data if available and we don't have one cached
			if let sharedLocationData, cachedLocationData == nil {
				cachedLocationData = sharedLocationData
				cachedLocationDataCoordinate = sharedLocation
			}
			return sharedLocation
		}

		// Finally, fetch fresh location with timeout
		do {
			let location = try await fetchLocationWithTimeout(seconds: 10)
			cachedLocation = location
			cacheTimestamp = Date()
			return location
		} catch {
			// Fall back to cached location even if expired, or CLLocationManager's last known location
			return cachedLocation ?? CLLocationManager().location
		}
	}

	/// Retrieves cached location and placemark from the shared App Group
	private func getSharedAppGroupData() -> (location: CLLocation, locationData: LocationData?)? {
		guard let cached = LocationAppGroupCache.read() else { return nil }

		// Validate the cache is recent (within cache validity duration)
		let cacheAge = Date().timeIntervalSince(cached.timestamp)
		guard cacheAge < cacheValidityDuration else { return nil }

		let location = CLLocation(latitude: cached.location.latitude, longitude: cached.location.longitude)
		return (location, cached.location)
	}

	private func fetchLocationWithTimeout(seconds: TimeInterval) async throws -> CLLocation {
		try await withThrowingTaskGroup(of: CLLocation.self) { group in
			group.addTask {
				for try await update in CLLocationUpdate.liveUpdates() {
					if let location = update.location {
						return location
					}
				}
				throw CLError(.locationUnknown)
			}

			group.addTask {
				try await Task.sleep(for: .seconds(seconds))
				throw CLError(.locationUnknown)
			}

			let result = try await group.next()!
			group.cancelAll()
			return result
		}
	}

	/// Returns location with cached location data, only re-geocoding if location moved significantly
	func getLocationWithPlacemark() async -> (location: CLLocation?, locationData: LocationData?) {
		guard let location = await getLocation() else {
			return (nil, nil)
		}

		// Reuse cached location data if location hasn't moved significantly
		if let cached = cachedLocationData,
		   let cachedCoord = cachedLocationDataCoordinate,
		   location.distance(from: cachedCoord) < significantDistanceChange {
			return (location, cached)
		}

		// Need to geocode
		do {
			if let placemark = try await geocoder.reverseGeocodeLocation(location).first {
				let locationData = LocationData(
					title: placemark.locality,
					subtitle: placemark.country,
					latitude: location.coordinate.latitude,
					longitude: location.coordinate.longitude,
					timeZoneIdentifier: placemark.timeZone?.identifier
				)
				cachedLocationData = locationData
				cachedLocationDataCoordinate = location
				return (location, locationData)
			}
		} catch {
			// Fallback to cached location data if geocoding fails
			return (location, cachedLocationData)
		}

		return (location, nil)
	}
}
