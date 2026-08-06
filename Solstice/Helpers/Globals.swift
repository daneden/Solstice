//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import CoreLocation
import Foundation
import Observation

#if os(visionOS)
	import MapKit
#endif

var chartHeight: CGFloat = {
	#if !os(watchOS)
		360
	#else
		200
	#endif
}()

var chartMarkSize: Double = {
	#if os(watchOS)
		4
	#else
		6
	#endif
}()

let calendar = Calendar.autoupdatingCurrent

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

// MARK: - Localized Name Cache

/// Per-device, per-locale cache of reverse-geocoded location names, shared with
/// the widget/intents targets via the App Group. This is deliberately NOT written
/// back to the CloudKit-synced `SavedLocation.title`/`subtitle`: those stay as the
/// coordinate's original seed/fallback, and each device derives a display name in
/// its own locale — otherwise two devices in different languages would fight over
/// the synced record.
enum LocalizedNameCache {
	struct Entry: Codable {
		var title: String?
		var subtitle: String?
		var timestamp: Date
	}

	struct Hit {
		var title: String?
		var subtitle: String?
		var isStale: Bool
	}

	/// Names change rarely (geopolitics, spelling); refresh at most monthly.
	static let staleness: TimeInterval = 30 * 24 * 60 * 60

	private static let storageKey = "localizedNameCache"

	private static var defaults: UserDefaults? {
		UserDefaults(suiteName: Constants.appGroupIdentifier)
	}

	/// Cache key buckets coordinates to ~110m (3 dp) and includes the current
	/// locale, so a language change is a cache miss that triggers a fresh geocode.
	static func key(latitude: Double, longitude: Double) -> String {
		let lat = (latitude * 1000).rounded() / 1000
		let lon = (longitude * 1000).rounded() / 1000
		return "\(lat)|\(lon)|\(Locale.current.identifier)"
	}

	private static func load() -> [String: Entry] {
		guard let data = defaults?.data(forKey: storageKey),
		      let dict = try? JSONDecoder().decode([String: Entry].self, from: data)
		else { return [:] }
		return dict
	}

	private static func store(_ dict: [String: Entry]) {
		guard let data = try? JSONEncoder().encode(dict) else { return }
		defaults?.set(data, forKey: storageKey)
	}

	static func read(key: String) -> Hit? {
		guard let entry = load()[key] else { return nil }
		return Hit(
			title: entry.title,
			subtitle: entry.subtitle,
			isStale: Date().timeIntervalSince(entry.timestamp) > staleness
		)
	}

	static func write(key: String, title: String?, subtitle: String?) {
		var dict = load()
		dict[key] = Entry(title: title, subtitle: subtitle, timestamp: Date())
		store(dict)
	}

	/// Synchronous best-effort localized name for targets without the reactive
	/// resolver (widgets, intents): cached value if present, else the stored value.
	static func cachedName(for location: some AnyLocation) -> (title: String?, subtitle: String?) {
		let hit = read(key: key(latitude: location.latitude, longitude: location.longitude))
		return (hit?.title ?? location.title, hit?.subtitle ?? location.subtitle)
	}
}

// MARK: - Reverse Geocoding

/// The subset of reverse-geocoding results the app uses, decoupled from
/// `CLPlacemark` so each platform can source it from a non-deprecated API.
struct ReverseGeocodedPlace {
	var city: String?
	var country: String?
	var timeZone: TimeZone?
}

enum ReverseGeocoder {
	/// Reverse geocodes via MapKit on visionOS, where `CLGeocoder` is deprecated
	/// (deployment target 26+). The other platforms' deployment targets predate
	/// `MKReverseGeocodingRequest`, so they stay on `CLGeocoder`.
	static func reverseGeocode(_ location: CLLocation) async -> ReverseGeocodedPlace? {
		#if os(visionOS)
			guard let request = MKReverseGeocodingRequest(location: location),
			      let mapItem = try? await request.mapItems.first
			else { return nil }
			return ReverseGeocodedPlace(
				city: mapItem.addressRepresentations?.cityName,
				country: mapItem.addressRepresentations?.regionName,
				timeZone: mapItem.timeZone
			)
		#else
			guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
			else { return nil }
			return ReverseGeocodedPlace(
				city: placemark.locality,
				country: placemark.country,
				timeZone: placemark.timeZone
			)
		#endif
	}
}

// MARK: - Location Name Resolver

/// Reactively resolves localized display names for saved locations. Views read
/// `displayName(for:)` synchronously (falling back to the stored name); when a
/// geocode lands it updates the observed store, re-rendering the observing views.
@Observable
final class LocationNameResolver {
	private struct ResolvedName {
		var title: String?
		var subtitle: String?
	}

	/// Observed — mutating this drives SwiftUI updates.
	private var resolved: [String: ResolvedName] = [:]

	/// Keys with an in-flight resolve, so concurrent renders don't stack geocodes.
	@ObservationIgnored private var working: Set<String> = []

	/// Localized display name for `location`, falling back to its stored values.
	/// Non-mutating from the caller's perspective; kicks off an async geocode when
	/// the cache is missing or stale.
	func displayName(for location: some AnyLocation) -> (title: String?, subtitle: String?) {
		// The current location is already reverse-geocoded live in the active locale.
		if location is CurrentLocation {
			return (location.title, location.subtitle)
		}

		let key = LocalizedNameCache.key(latitude: location.latitude, longitude: location.longitude)

		if let mem = resolved[key] {
			return (mem.title ?? location.title, mem.subtitle ?? location.subtitle)
		}

		ensureResolved(latitude: location.latitude, longitude: location.longitude, key: key)

		if let hit = LocalizedNameCache.read(key: key) {
			return (hit.title ?? location.title, hit.subtitle ?? location.subtitle)
		}
		return (location.title, location.subtitle)
	}

	private func ensureResolved(latitude: Double, longitude: Double, key: String) {
		guard !working.contains(key) else { return }
		working.insert(key)

		Task { @MainActor in
			defer { working.remove(key) }

			if let hit = LocalizedNameCache.read(key: key) {
				resolved[key] = ResolvedName(title: hit.title, subtitle: hit.subtitle)
				if !hit.isStale { return }
			}

			#if DEBUG
				// Fixtures are pre-seeded during capture; a geocode here means a cache
				// miss slipped through (network-dependent, non-deterministic).
				if ScreenshotLaunch.isCapturing {
					print("⚠️ [screenshots] geocoding \(key) — not pre-seeded")
				}
			#endif
			let clLocation = CLLocation(latitude: latitude, longitude: longitude)
			guard let place = await ReverseGeocoder.reverseGeocode(clLocation) else { return }
			let title = place.city
			let subtitle = place.country
			guard title != nil || subtitle != nil else { return }

			LocalizedNameCache.write(key: key, title: title, subtitle: subtitle)
			resolved[key] = ResolvedName(title: title, subtitle: subtitle)
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
