//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

var chartHeight: CGFloat = {
#if !os(watchOS)
	300
#else
	200
#endif
}()

var chartMarkSize: Double = {
#if os(watchOS)
	4
#else
	8
#endif
}()

let calendar =  Calendar.autoupdatingCurrent

let localTimeZone = TimeZone.ReferenceType.local

// MARK: - Unified Location Data
/// A unified struct for encoding/decoding location data across all targets.
/// Used for App Group cache, AppIntents entity IDs, and JSON serialization.
struct LocationData: Codable, AnyLocation {
	var title: String?
	var subtitle: String?
	var latitude: Double
	var longitude: Double
	var timeZoneIdentifier: String?
	var uuid: UUID?

	init(
		title: String? = nil,
		subtitle: String? = nil,
		latitude: Double,
		longitude: Double,
		timeZoneIdentifier: String? = nil,
		uuid: UUID? = nil
	) {
		self.title = title
		self.subtitle = subtitle
		self.latitude = latitude
		self.longitude = longitude
		self.timeZoneIdentifier = timeZoneIdentifier
		self.uuid = uuid
	}
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

		let title = defaults.string(forKey: "cachedPlacemarkTitle")
		let subtitle = defaults.string(forKey: "cachedPlacemarkSubtitle")
		let timeZoneIdentifier = defaults.string(forKey: "cachedPlacemarkTimeZone")

		// Only create location data if we have meaningful placemark data
		let hasPlacemarkData = title != nil || timeZoneIdentifier != nil
		guard hasPlacemarkData else { return nil }

		let location = LocationData(
			title: title,
			subtitle: subtitle,
			latitude: latitude,
			longitude: longitude,
			timeZoneIdentifier: timeZoneIdentifier
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

// MARK: - App Constants
enum Constants {
	/// App Group identifier for sharing data between app and extensions
	static let appGroupIdentifier = "group.me.daneden.Solstice"

	/// iCloud container identifier for CloudKit sync
	static let iCloudContainerIdentifier = "iCloud.me.daneden.Solstice"

	/// Background task identifier for notification scheduling
	static let backgroundTaskIdentifier = "me.daneden.Solstice.notificationScheduler"

	/// User activity type for viewing locations (Handoff/Spotlight)
	static let viewLocationActivityType = "me.daneden.Solstice.viewLocation"

	/// Prefix for notification request identifiers
	static let notificationIdentifierPrefix = "me.daneden.Solstice.notification-"

	/// URL scheme for deep links
	static let urlScheme = "solstice"

	/// Deep link path for current location
	static let currentLocationPath = "currentLocation"

	/// Deep link path for coordinates
	static let coordinatesPath = "coordinates"

	enum IAPProducts {
		static let tipSmall = "me.daneden.Solstice.iap.tip.small"
		static let tipMedium = "me.daneden.Solstice.iap.tip.medium"
		static let tipLarge = "me.daneden.Solstice.iap.tip.large"

		static let all = [tipSmall, tipMedium, tipLarge]
	}
}
