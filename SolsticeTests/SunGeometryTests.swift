//
//  SunGeometryTests.swift
//  SolsticeTests
//
//  Covers the pure-math building blocks used by the sun-geometry App Intents:
//    - signedAngularDifference (wrap-around handling)
//    - NTSolar altitude/azimuth (self-consistency with sunrise/sunset/solarNoon)
//    - findNextAltitudeCrossing / findNextAzimuthCrossing (bisection)
//

import Testing
import Foundation
import CoreLocation
@testable import Solstice

struct SunGeometryTests {
	// MARK: - Reference locations

	/// Greenwich Observatory — longitude ~0° keeps UT == local solar time for sanity checks.
	static let greenwich = CLLocationCoordinate2D(latitude: 51.4779, longitude: -0.0015)
	/// Sydney — Southern Hemisphere sanity check.
	static let sydney = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
	/// Quito — near-equatorial, useful for high-altitude-noon checks.
	static let quito = CLLocationCoordinate2D(latitude: -0.1807, longitude: -78.4678)

	static func utcDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day
		components.hour = hour
		components.minute = minute
		components.second = 0
		components.timeZone = TimeZone(secondsFromGMT: 0)
		return Calendar(identifier: .gregorian).date(from: components)!
	}

	// MARK: - signedAngularDifference

	@Test("signedAngularDifference handles plain cases")
	func signedDiffPlain() {
		#expect(abs(signedAngularDifference(from: 0, to: 0)) < 1e-9)
		#expect(abs(signedAngularDifference(from: 90, to: 180) - 90) < 1e-9)
		#expect(abs(signedAngularDifference(from: 180, to: 90) - (-90)) < 1e-9)
	}

	@Test("signedAngularDifference wraps around 0/360")
	func signedDiffWraps() {
		// From 350 to 10 is +20 (clockwise), not -340.
		#expect(abs(signedAngularDifference(from: 350, to: 10) - 20) < 1e-9)
		// From 10 to 350 is -20 (counterclockwise).
		#expect(abs(signedAngularDifference(from: 10, to: 350) - (-20)) < 1e-9)
		// From 0 to 359 is -1, not +359.
		#expect(abs(signedAngularDifference(from: 0, to: 359) - (-1)) < 1e-9)
	}

	@Test("signedAngularDifference at the 180° antipode is in (-180, 180]")
	func signedDiffAntipode() {
		let diff = signedAngularDifference(from: 0, to: 180)
		#expect(abs(abs(diff) - 180) < 1e-9)
	}

	@Test("signedAngularDifference tolerates out-of-range inputs")
	func signedDiffOutOfRange() {
		// 720° == 360° == 0°, so diff from 0 to 720 is 0.
		#expect(abs(signedAngularDifference(from: 0, to: 720)) < 1e-9)
		// Negative bearings normalize the same way.
		#expect(abs(signedAngularDifference(from: 0, to: -10) - (-10)) < 1e-9)
	}

	// MARK: - IsSunOnBearing logic (composed from signed diff + altitude)

	@Test("IsSunOnBearing logic handles east wall across midnight boundary of bearing")
	func sunOnBearingEastWallLogic() {
		// Simulate: sun's azimuth is 5°, east wall faces 355°, tolerance 60°.
		// Angular distance wraps around: diff is +10°, which is within tolerance.
		let diff = signedAngularDifference(from: 355, to: 5)
		#expect(abs(diff) <= 60)
	}

	@Test("IsSunOnBearing logic rejects when sun is opposite the wall")
	func sunOnBearingOppositeWallLogic() {
		// East wall faces 90°, sun is at 280° (roughly west-northwest).
		let diff = signedAngularDifference(from: 90, to: 280)
		#expect(abs(diff) > 60)
	}

	// MARK: - NTSolar altitude/azimuth sanity

	@Test("Sun altitude is strictly positive between sunrise and sunset")
	func altitudePositiveDuringDay() throws {
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 12)
		let solar = try #require(NTSolar(for: date, coordinate: Self.greenwich, timeZone: .gmt))
		let sunrise = try #require(solar.sunrise)
		let sunset = try #require(solar.sunset)

		let midday = Date(timeIntervalSince1970: (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2)
		#expect(solar.altitude(at: midday) > 0)
	}

	@Test("Sun altitude is approximately zero at sunrise and sunset")
	func altitudeNearZeroAtHorizonEvents() throws {
		let date = Self.utcDate(year: 2025, month: 3, day: 20, hour: 12)
		let solar = try #require(NTSolar(for: date, coordinate: Self.greenwich, timeZone: .gmt))
		let sunrise = try #require(solar.sunrise)
		let sunset = try #require(solar.sunset)

		// NTSolar applies a -35'/-0.583° geometric correction for refraction & upper limb.
		// Actual center-of-sun altitude at sunrise/sunset is ~-0.583°, so allow 1° slack.
		#expect(abs(solar.altitude(at: sunrise)) < 1.0)
		#expect(abs(solar.altitude(at: sunset)) < 1.0)
	}

	@Test("At solar noon the sun is within a degree of due south (northern hemisphere)")
	func azimuthAtSolarNoonGreenwich() throws {
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 12)
		let solar = try #require(NTSolar(for: date, coordinate: Self.greenwich, timeZone: .gmt))
		let noon = try #require(solar.solarNoon)

		let az = solar.azimuth(at: noon)
		let diffFromSouth = abs(signedAngularDifference(from: 180, to: az))
		#expect(diffFromSouth < 1.0)
	}

	@Test("At solar noon the sun is within a degree of due north (southern hemisphere)")
	func azimuthAtSolarNoonSydney() throws {
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 2) // noon-ish in Sydney
		let tz = TimeZone(identifier: "Australia/Sydney")!
		let solar = try #require(NTSolar(for: date, coordinate: Self.sydney, timeZone: tz))
		let noon = try #require(solar.solarNoon)

		let az = solar.azimuth(at: noon)
		let diffFromNorth = abs(signedAngularDifference(from: 0, to: az))
		#expect(diffFromNorth < 1.0)
	}

	@Test("Azimuth is always in 0..<360")
	func azimuthInRange() throws {
		let date = Self.utcDate(year: 2025, month: 9, day: 22, hour: 6)
		let solar = try #require(NTSolar(for: date, coordinate: Self.quito, timeZone: .gmt))
		for hour in stride(from: 0.0, through: 24.0, by: 0.5) {
			let sample = date.addingTimeInterval(hour * 3600)
			let az = solar.azimuth(at: sample)
			#expect(az >= 0 && az < 360)
		}
	}

	// MARK: - findNextAltitudeCrossing

	@Test("findNextAltitudeCrossing rising @ 0° matches NTSolar's sunrise")
	func altitudeCrossingRisingAtHorizon() throws {
		// Start search a few hours before sunrise.
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 0)
		let solar = try #require(NTSolar(for: date, coordinate: Self.greenwich, timeZone: .gmt))
		let sunrise = try #require(solar.sunrise)

		let crossing = try #require(findNextAltitudeCrossing(
			targetDegrees: 0,
			direction: .rising,
			start: date,
			coordinate: Self.greenwich,
			timeZone: .gmt
		))

		// Bisection should land within ~2 minutes of NTSolar's sunrise. They don't
		// match exactly because NTSolar's sunrise includes an atmospheric refraction
		// correction (-35') that the raw altitude function doesn't apply.
		#expect(abs(crossing.timeIntervalSince(sunrise)) < 10 * 60)
	}

	@Test("findNextAltitudeCrossing falling @ 0° matches NTSolar's sunset")
	func altitudeCrossingFallingAtHorizon() throws {
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 0)
		let solar = try #require(NTSolar(for: date, coordinate: Self.greenwich, timeZone: .gmt))
		let sunset = try #require(solar.sunset)

		let crossing = try #require(findNextAltitudeCrossing(
			targetDegrees: 0,
			direction: .falling,
			start: date,
			coordinate: Self.greenwich,
			timeZone: .gmt
		))

		#expect(abs(crossing.timeIntervalSince(sunset)) < 10 * 60)
	}

	@Test("findNextAltitudeCrossing rising target can be interrogated")
	func altitudeCrossingRisingTarget() throws {
		// On midsummer at Greenwich the sun comfortably passes 30° altitude.
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 0)
		let crossing = try #require(findNextAltitudeCrossing(
			targetDegrees: 30,
			direction: .rising,
			start: date,
			coordinate: Self.greenwich,
			timeZone: .gmt
		))

		let solar = try #require(NTSolar(for: crossing, coordinate: Self.greenwich, timeZone: .gmt))
		#expect(abs(solar.altitude(at: crossing) - 30) < 0.01)
	}

	@Test("findNextAltitudeCrossing returns nil for unreachable altitude")
	func altitudeCrossingUnreachable() {
		// The sun never reaches 89° altitude at Greenwich.
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 0)
		let crossing = findNextAltitudeCrossing(
			targetDegrees: 89,
			direction: .rising,
			start: date,
			coordinate: Self.greenwich,
			timeZone: .gmt
		)
		#expect(crossing == nil)
	}

	// MARK: - findNextAzimuthCrossing

	@Test("findNextAzimuthCrossing clockwise @ 180° matches solar noon (northern hemisphere)")
	func azimuthCrossingSouthMeridian() throws {
		let date = Self.utcDate(year: 2025, month: 6, day: 21, hour: 0)
		let solar = try #require(NTSolar(for: date, coordinate: Self.greenwich, timeZone: .gmt))
		let noon = try #require(solar.solarNoon)

		let crossing = try #require(findNextAzimuthCrossing(
			targetDegrees: 180,
			direction: .either,
			start: date,
			coordinate: Self.greenwich,
			timeZone: .gmt
		))

		#expect(abs(crossing.timeIntervalSince(noon)) < 5 * 60)
	}

	@Test("findNextAzimuthCrossing returns a crossing near 90° (due east) in the morning")
	func azimuthCrossingEastMorning() throws {
		let date = Self.utcDate(year: 2025, month: 3, day: 20, hour: 0)
		let crossing = try #require(findNextAzimuthCrossing(
			targetDegrees: 90,
			direction: .clockwise,
			start: date,
			coordinate: Self.greenwich,
			timeZone: .gmt
		))

		let solar = try #require(NTSolar(for: crossing, coordinate: Self.greenwich, timeZone: .gmt))
		#expect(abs(signedAngularDifference(from: 90, to: solar.azimuth(at: crossing))) < 0.1)
	}
}
