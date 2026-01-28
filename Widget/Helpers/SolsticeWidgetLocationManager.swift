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
		if let sharedLocation = getSharedAppGroupLocation() {
			cachedLocation = sharedLocation
			cacheTimestamp = Date()
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

	/// Retrieves cached location from the shared App Group UserDefaults
	private func getSharedAppGroupLocation() -> CLLocation? {
		guard let defaults = UserDefaults(suiteName: Constants.appGroupIdentifier) else { return nil }

		let latitude = defaults.double(forKey: "cachedLatitude")
		let longitude = defaults.double(forKey: "cachedLongitude")
		let timestamp = defaults.double(forKey: "cachedLocationTimestamp")

		// Validate the cached data exists and is recent (within cache validity duration)
		guard latitude != 0, longitude != 0, timestamp > 0 else { return nil }

		let cacheAge = Date().timeIntervalSince1970 - timestamp
		guard cacheAge < cacheValidityDuration else { return nil }

		return CLLocation(latitude: latitude, longitude: longitude)
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
}
