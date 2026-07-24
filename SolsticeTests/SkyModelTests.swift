//
//  SkyModelTests.swift
//  SolsticeTests
//
//  Exercises the physics-based sky model behind SkyGradient.
//

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

	@Test("The glow brightens toward the sun (higher scattering cosine)")
	func glowPeaksTowardTheSun() {
		func brightness(_ cosTheta: Double) -> Double {
			luminance(model.radiance(sunAltitudeDeg: 20, viewElevationDeg: 20, scatterCosTheta: cosTheta))
		}
		// Forward Mie scattering: brightest looking straight at the sun, dimmest facing away.
		#expect(brightness(1) > brightness(0))
		#expect(brightness(0) > brightness(-1))
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
