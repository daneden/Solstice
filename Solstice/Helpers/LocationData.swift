//
//  LocationData.swift
//  Solstice
//

import Foundation

/// A unified struct for encoding/decoding location data across all targets.
/// Used for App Group cache, AppIntents entity IDs, and JSON serialization.
struct LocationData: Codable, AnyLocation {
	var title: String?
	var subtitle: String?
	var latitude: Double
	var longitude: Double
	var timeZoneIdentifier: String?
	var uuid: UUID?
}

// MARK: - Location App Group Cache

enum LocationAppGroupCache {
	struct CachedData {
		var location: LocationData
		var timestamp: Date
	}

	private static var defaults: UserDefaults? {
		UserDefaults(suiteName: Constants.appGroupIdentifier)
	}

	static func read() -> CachedData? {
		guard let defaults else { return nil }

		let latitude = defaults.double(forKey: "cachedLatitude")
		let longitude = defaults.double(forKey: "cachedLongitude")
		let timestamp = defaults.double(forKey: "cachedLocationTimestamp")

		guard latitude != 0, longitude != 0, timestamp > 0 else { return nil }

		// Return location data even if placemark fields are nil
		// Widget will trigger geocoding if timeZoneIdentifier is missing
		let location = LocationData(
			title: defaults.string(forKey: "cachedPlacemarkTitle"),
			subtitle: defaults.string(forKey: "cachedPlacemarkSubtitle"),
			latitude: latitude,
			longitude: longitude,
			timeZoneIdentifier: defaults.string(forKey: "cachedPlacemarkTimeZone")
		)

		return CachedData(
			location: location,
			timestamp: Date(timeIntervalSince1970: timestamp)
		)
	}

	static func write(_ location: LocationData) {
		guard let defaults else { return }

		defaults.set(location.latitude, forKey: "cachedLatitude")
		defaults.set(location.longitude, forKey: "cachedLongitude")
		defaults.set(Date().timeIntervalSince1970, forKey: "cachedLocationTimestamp")
		defaults.set(location.title, forKey: "cachedPlacemarkTitle")
		defaults.set(location.subtitle, forKey: "cachedPlacemarkSubtitle")
		defaults.set(location.timeZoneIdentifier, forKey: "cachedPlacemarkTimeZone")
	}
}
