//
//  ReverseGeocoder.swift
//  Solstice
//

import CoreLocation

#if os(visionOS)
	import MapKit
#endif

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
