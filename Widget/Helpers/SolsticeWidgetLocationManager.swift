//
//  SolsticeWidgetLocationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 20/01/2026.
//
import Foundation
import CoreLocation
import OSLog

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
			let age = Date().timeIntervalSince(cacheTimestamp)
			WidgetLogger.location.debug("In-memory cache hit (age: \(String(format: "%.0f", age))s)")
			return cachedLocation
		}

		// Second, check the shared App Group cache from the main app
		if let (sharedLocation, sharedLocationData) = getSharedAppGroupData() {
			WidgetLogger.location.debug("App Group cache hit (\(sharedLocation.coordinate.latitude), \(sharedLocation.coordinate.longitude))")
			cachedLocation = sharedLocation
			cacheTimestamp = Date()
			if let sharedLocationData, cachedLocationData == nil {
				cachedLocationData = sharedLocationData
				cachedLocationDataCoordinate = sharedLocation
			}
			return sharedLocation
		}

		// Finally, fetch fresh location with timeout
		WidgetLogger.location.info("No cache available, fetching fresh location…")
		do {
			let location = try await fetchLocationWithTimeout(seconds: 10)
			WidgetLogger.location.info("Fresh location fetched: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
			WidgetLogStore.log(.location, "Fresh location fetched", metadata: [
				"lat": String(format: "%.4f", location.coordinate.latitude),
				"lon": String(format: "%.4f", location.coordinate.longitude)
			])
			cachedLocation = location
			cacheTimestamp = Date()
			return location
		} catch {
			let fallback = cachedLocation ?? CLLocationManager().location
			WidgetLogger.location.warning("Location fetch failed, using fallback: \(fallback != nil ? "available" : "nil")")
			WidgetLogStore.log(.error, "Location fetch failed", metadata: [
				"error": error.localizedDescription,
				"hasFallback": "\(fallback != nil)"
			])
			return fallback
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
		let start = Date()
		do {
			let location = try await withThrowingTaskGroup(of: CLLocation.self) { group in
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
			let elapsed = Date().timeIntervalSince(start)
			WidgetLogger.location.debug("Location fetched in \(String(format: "%.1f", elapsed))s")
			return location
		} catch {
			let elapsed = Date().timeIntervalSince(start)
			WidgetLogger.location.warning("Location fetch timed out after \(String(format: "%.1f", elapsed))s")
			WidgetLogStore.log(.error, "Location fetch timeout", metadata: [
				"elapsed": String(format: "%.1f", elapsed),
				"timeout": "\(seconds)"
			])
			throw error
		}
	}

	/// Returns location with cached location data, only re-geocoding if location moved significantly
	func getLocationWithPlacemark() async -> (location: CLLocation?, locationData: LocationData?) {
		guard let location = await getLocation() else {
			WidgetLogger.location.warning("getLocationWithPlacemark: no location available")
			return (nil, nil)
		}

		// Reuse cached location data if location hasn't moved significantly
		if let cached = cachedLocationData,
		   let cachedCoord = cachedLocationDataCoordinate,
		   location.distance(from: cachedCoord) < significantDistanceChange {
			let distance = location.distance(from: cachedCoord)
			WidgetLogger.location.debug("Reusing cached placemark (moved \(String(format: "%.0f", distance))m, threshold \(self.significantDistanceChange)m)")
			return (location, cached)
		}

		// Need to geocode
		WidgetLogger.location.debug("Re-geocoding location (moved significantly or no cache)")
		do {
			if let placemark = try await geocoder.reverseGeocodeLocation(location).first {
				let locationData = LocationData(
					title: placemark.locality,
					subtitle: placemark.country,
					latitude: location.coordinate.latitude,
					longitude: location.coordinate.longitude,
					timeZoneIdentifier: placemark.timeZone?.identifier
				)
				WidgetLogger.location.debug("Geocoded: \(placemark.locality ?? "nil", privacy: .public), tz: \(placemark.timeZone?.identifier ?? "nil")")
				cachedLocationData = locationData
				cachedLocationDataCoordinate = location
				return (location, locationData)
			}
		} catch {
			WidgetLogger.location.error("Geocoding failed: \(error.localizedDescription)")
			return (location, cachedLocationData)
		}

		return (location, nil)
	}
}
