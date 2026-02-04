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

// MARK: - Location App Group Cache
enum LocationAppGroupCache {
	struct CachedPlacemark {
		var title: String?
		var subtitle: String?
		var timeZoneIdentifier: String?
	}

	struct CachedData {
		var latitude: Double
		var longitude: Double
		var timestamp: Date
		var placemark: CachedPlacemark?
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

		let placemark = CachedPlacemark(
			title: defaults.string(forKey: "cachedPlacemarkTitle"),
			subtitle: defaults.string(forKey: "cachedPlacemarkSubtitle"),
			timeZoneIdentifier: defaults.string(forKey: "cachedPlacemarkTimeZone")
		)

		// Only include placemark if it has meaningful data
		let hasPlacemarkData = placemark.title != nil || placemark.timeZoneIdentifier != nil

		return CachedData(
			latitude: latitude,
			longitude: longitude,
			timestamp: Date(timeIntervalSince1970: timestamp),
			placemark: hasPlacemarkData ? placemark : nil
		)
	}

	static func write(latitude: Double, longitude: Double, placemark: CachedPlacemark? = nil) {
		guard let defaults else { return }

		defaults.set(latitude, forKey: "cachedLatitude")
		defaults.set(longitude, forKey: "cachedLongitude")
		defaults.set(Date().timeIntervalSince1970, forKey: "cachedLocationTimestamp")

		if let placemark {
			defaults.set(placemark.title, forKey: "cachedPlacemarkTitle")
			defaults.set(placemark.subtitle, forKey: "cachedPlacemarkSubtitle")
			defaults.set(placemark.timeZoneIdentifier, forKey: "cachedPlacemarkTimeZone")
		}
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
