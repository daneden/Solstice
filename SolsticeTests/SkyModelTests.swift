//
//  SkyModelTests.swift
//  SolsticeTests
//
//  Exercises the physics-based sky model behind SkyGradient.
//

import CoreLocation
import Foundation
@testable import Solstice
import SwiftUI
import Testing

struct SkyModelTests {
	let model = SkyModel.standard

	private func luminance(_ rgb: SIMD3<Double>) -> Double {
		0.2126 * rgb.x + 0.7152 * rgb.y + 0.0722 * rgb.z
	}

	@Test("Daylight sky is far brighter than deep twilight")
	func daylightBrighterThanTwilight() {
		let day = luminance(model.radiance(sunAltitudeDeg: 45, viewElevationDeg: 80, scatterCosTheta: 0.5))
		let twilight = luminance(model.radiance(sunAltitudeDeg: -10, viewElevationDeg: 80, scatterCosTheta: 0.5))
		#expect(day > twilight)
	}

	@Test("Zenith brightness increases as the sun climbs")
	func brightnessMonotonicWithAltitude() {
		func zenith(_ altitude: Double) -> Double {
			luminance(model.radiance(sunAltitudeDeg: altitude, viewElevationDeg: 80, scatterCosTheta: 0.5))
		}
		let samples = [5.0, 20, 40, 60].map(zenith)
		for (lower, higher) in zip(samples, samples.dropFirst()) {
			#expect(higher > lower)
		}
	}

	@Test("The horizon reddens as the sun descends")
	func horizonRedensAtLowSun() {
		func redToBlue(_ altitude: Double) -> Double {
			let rgb = model.radiance(sunAltitudeDeg: altitude, viewElevationDeg: 2, scatterCosTheta: 1)
			return rgb.x / max(rgb.z, 1e-12)
		}
		#expect(redToBlue(3) > redToBlue(30))
	}

	@Test("The glow peaks looking straight at the sun")
	func glowPeaksTowardTheSun() {
		func brightness(_ cosTheta: Double) -> Double {
			luminance(model.radiance(sunAltitudeDeg: 20, viewElevationDeg: 20, scatterCosTheta: cosTheta))
		}
		// The forward-Mie lobe makes looking at the sun the brightest direction. (Rayleigh alone is
		// symmetric, so side-scatter is not necessarily dimmer than back-scatter — don't assert that.)
		#expect(brightness(1) > brightness(0))
		#expect(brightness(1) > brightness(-1))
	}

	@Test("Physical sky goes dark once the sun is well below the horizon")
	func nightPhysicalGoesDark() {
		let night = luminance(model.radiance(sunAltitudeDeg: -30, viewElevationDeg: 30, scatterCosTheta: 0.5))
		#expect(night < 1e-3)
	}

	@Test("Mesh is well formed with finite colours")
	func meshWellFormed() {
		let mesh = model.mesh(sunAltitudeDeg: 20)
		#expect(mesh.stops.count == model.meshHeight)

		let env = EnvironmentValues()
		for color in mesh.stops.map({ $0.resolve(in: env) }) {
			#expect(color.red.isFinite && color.green.isFinite && color.blue.isFinite)
		}
	}

	private func resolvedLuminance(_ color: Color) -> Double {
		let resolved = color.resolve(in: EnvironmentValues())
		return 0.2126 * Double(resolved.red) + 0.7152 * Double(resolved.green) + 0.0722 * Double(resolved.blue)
	}

	@Test("Ground band below the horizon is darker than the sky above it, and fades with depth")
	func groundBandDarkerThanHorizonSky() {
		let mesh = model.mesh(sunAltitudeDeg: 30, horizonFraction: 0.6)
		#expect(mesh.stops.count == model.meshHeight)

		// Rows: [0 ..< meshHeight - 2] sky (top → horizon), then two ground rows.
		let horizonSky = resolvedLuminance(mesh.stops[model.meshHeight - 3])
		let groundTop = resolvedLuminance(mesh.stops[model.meshHeight - 2])
		let groundBottom = resolvedLuminance(mesh.stops[model.meshHeight - 1])

		#expect(groundTop < horizonSky)
		#expect(groundBottom < groundTop)

		let env = EnvironmentValues()
		for color in mesh.stops.map({ $0.resolve(in: env) }) {
			#expect(color.red.isFinite && color.green.isFinite && color.blue.isFinite)
		}
	}

	/// London on the 2026 June solstice at the given hour — the shared fixture for dial tests.
	private func londonSolar(hour: Int) throws -> NTSolar {
		let timeZone = try #require(TimeZone(identifier: "Europe/London"))
		let date = try #require(DateComponents(calendar: Calendar(identifier: .gregorian),
		                                       timeZone: timeZone,
		                                       year: 2026, month: 6, day: 21, hour: hour).date)
		let coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
		return try #require(NTSolar(for: date, coordinate: coordinate, timeZone: timeZone))
	}

	@Test("Dial stops are brighter at noon than at midnight, and the ring closes seamlessly")
	func dialStopsDayNightContrast() throws {
		let stops = try SkyModel.standard.dialStops(for: londonSolar(hour: 12))
		#expect(stops.first?.location == 0)
		#expect(stops.last?.location == 1)

		func luminance(nearest location: Double) -> Double {
			let stop = stops.min { abs($0.location - location) < abs($1.location - location) }!
			return resolvedLuminance(stop.color)
		}

		#expect(luminance(nearest: 0.5) > luminance(nearest: 0))
		#expect(luminance(nearest: 1) == luminance(nearest: 0))
	}

	@Test("Cached mesh matches a direct render of the quantised inputs")
	func cachedMeshMatchesDirectRender() {
		let cached = model.cachedMesh(sunAltitudeDeg: 17.03, horizonFraction: 0.61)
		let direct = model.mesh(sunAltitudeDeg: (17.03 * 10).rounded() / 10,
		                        horizonFraction: (0.61 * 256).rounded() / 256)
		#expect(cached.stops == direct.stops)

		// A second call must return the identical memoized result.
		let secondHit = model.cachedMesh(sunAltitudeDeg: 17.03, horizonFraction: 0.61)
		#expect(secondHit.stops == cached.stops)
	}

	@Test("Glow stops peak at the centre and fade to nothing")
	func glowStopsFadeOutward() {
		let stops = SkyModel.standard.glowStops(sunAltitudeDeg: 20)
		#expect(stops.first?.location == 0)
		#expect(stops.last?.location == 1)

		let luminances = stops.map { resolvedLuminance($0.color) }
		let first = luminances[0], mid = luminances[luminances.count / 2], last = luminances[luminances.count - 1]
		#expect(first > mid)
		#expect(mid >= last)
		// The outermost stop is (near) black, so the additive layer vanishes at its edge.
		#expect(last < 0.02)
	}

	@Test("Below-horizon dial segments are solid per twilight band")
	func dialTwilightSegmentsAreSolid() throws {
		let solar = try londonSolar(hour: 12)
		let stops = SkyModel.standard.dialStops(for: solar)
		let start = solar.startOfDay
		func fraction(_ date: Date) -> Double {
			date.timeIntervalSince(start) / .twentyFourHours
		}

		// Every stop strictly inside the evening civil-twilight band must share one colour.
		let bandStart = try fraction(#require(solar.sunset))
		let bandEnd = try fraction(#require(solar.civilSunset))
		let band = stops.filter { $0.location > bandStart + 0.0002 && $0.location < bandEnd - 0.0002 }
		#expect(band.count >= 1)
		for stop in band {
			#expect(stop.color == band[0].color)
		}

		// And it must be a saturated blue, not grey: blue well above red.
		let civil = try #require(band.first).color.resolve(in: EnvironmentValues())
		#expect(civil.blue > civil.red * 2)
	}

	@Test("Below-horizon wedges brighten with the current daylight")
	func dialWedgesBrightenWithDaylight() throws {
		// The first stop sits at the midnight angle, inside the night wedge: it should be lifted
		// while the sun is high and settle back to the deep floor at night.
		let duringDay = try #require(SkyModel.standard.dialStops(for: londonSolar(hour: 13)).first)
		let duringNight = try #require(SkyModel.standard.dialStops(for: londonSolar(hour: 0)).first)
		#expect(resolvedLuminance(duringDay.color) > resolvedLuminance(duringNight.color))
	}

	@Test("High-sun horizon stays blue rather than yellow-green")
	func highSunHorizonStaysBlue() {
		// Single scattering alone goes green here; the multiple-scattering fill keeps it blue.
		let rgb = model.radiance(sunAltitudeDeg: 60, viewElevationDeg: model.minElevationDeg, scatterCosTheta: 0.3)
		#expect(rgb.z > rgb.y)
	}

	@Test("Radiance stays finite and non-negative across every angle")
	func radianceNeverNaN() {
		for sunAltitude in stride(from: -90.0, through: 90, by: 7.5) {
			for viewElevation in stride(from: 0.0, through: 90, by: 15) {
				for cosTheta in stride(from: -1.0, through: 1, by: 0.25) {
					let rgb = model.radiance(sunAltitudeDeg: sunAltitude,
					                         viewElevationDeg: viewElevation,
					                         scatterCosTheta: cosTheta)
					#expect(rgb.x.isFinite && rgb.y.isFinite && rgb.z.isFinite)
					#expect(rgb.x >= 0 && rgb.y >= 0 && rgb.z >= 0)
				}
			}
		}
	}
}
