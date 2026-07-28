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
		let mesh = model.mesh(sunAltitudeDeg: 20, sunAnchor: UnitPoint(x: 0.3, y: 0.4))
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
		let mesh = model.mesh(sunAltitudeDeg: 30, sunAnchor: UnitPoint(x: 0.5, y: 0.3), horizonFraction: 0.6)
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

	@Test("Dial stops are brighter at noon than at midnight, and the ring closes seamlessly")
	func dialStopsDayNightContrast() throws {
		let timeZone = try #require(TimeZone(identifier: "Europe/London"))
		let date = try #require(DateComponents(calendar: Calendar(identifier: .gregorian),
		                                       timeZone: timeZone,
		                                       year: 2026, month: 6, day: 21, hour: 12).date)
		let coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
		let solar = try #require(NTSolar(for: date, coordinate: coordinate, timeZone: timeZone))

		let stops = SkyModel.standard.dialStops(for: solar)
		#expect(stops.first?.location == 0)
		#expect(stops.last?.location == 1)

		func luminance(nearest location: Double) -> Double {
			let stop = stops.min { abs($0.location - location) < abs($1.location - location) }!
			return resolvedLuminance(stop.color)
		}

		#expect(luminance(nearest: 0.5) > luminance(nearest: 0))
		#expect(luminance(nearest: 1) == luminance(nearest: 0))
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
