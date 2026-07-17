// generate-localized-names.swift — one-off generator for the frozen fixture-name table.
//
// Reverse-geocodes each screenshot fixture coordinate under each shipping locale and
// prints a JSON table keyed by the same coordinate bucket the app's LocalizedNameCache
// uses. The output is HUMAN-REVIEWED (geocoder exonyms/gaps need a pass) and committed
// as `Data Model/screenshot-localized-names.json`, which `ScreenshotLaunch`
// pre-seeds during capture so localized names render deterministically, offline.
//
// Run:  swift Scripts/generate-localized-names.swift > /tmp/names.json
// Then review + patch gaps (some coords return no locality/placemark) and commit.
//
// NOTE: CLGeocoder delivers completions on the main thread, so the work runs in a
// Task with dispatchMain() (a blocking semaphore on main would deadlock).

import CoreLocation
import Foundation

/// Coordinates mirror Data Model/defaultData.json.
let fixtures: [(Double, Double)] = [
	(40.7128, -74.006), // New York
	(0.037423, -51.0724482), // Macapá
	(64.124287, -21.8904589), // Reykjavík
	(51.5033466, -0.0793965), // London
	(-22.6345606, 44.9999848), // Toliara
	(-43.533128, 172.6352929), // Christchurch
]
let locales = ["en", "de", "fr", "es", "ja", "ar", "nl", "zh-Hans", "pl", "it"]

func key(_ lat: Double, _ lon: Double) -> String {
	"\((lat * 1000).rounded() / 1000)|\((lon * 1000).rounded() / 1000)"
}

Task {
	let geocoder = CLGeocoder()
	var result: [String: [String: [String: String]]] = [:]
	for (lat, lon) in fixtures {
		let k = key(lat, lon)
		result[k] = [:]
		for loc in locales {
			let placemarks = try? await geocoder.reverseGeocodeLocation(
				CLLocation(latitude: lat, longitude: lon), preferredLocale: Locale(identifier: loc)
			)
			if let p = placemarks?.first {
				var e: [String: String] = [:]
				if let t = p.locality { e["title"] = t }
				if let s = p.country { e["subtitle"] = s }
				result[k]![loc] = e
			}
			try? await Task.sleep(nanoseconds: 600_000_000) // rate-limit
		}
	}
	let data = try! JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
	FileHandle.standardOutput.write(data)
	exit(0)
}

dispatchMain()
