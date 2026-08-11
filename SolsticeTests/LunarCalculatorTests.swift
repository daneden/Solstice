//
//  LunarCalculatorTests.swift
//  SolsticeTests
//
//  Reference values come from Meeus's own worked examples where they exist, and from
//  physical relationships that hold regardless of implementation where they don't.
//
//  Lifting the ephemeris out of `EclipseCalculator` made the first kind possible: the
//  lunar series can now be checked directly against the book rather than only indirectly,
//  through whether an eclipse came out in the right place.
//

import CoreLocation
import Foundation
@testable import Solstice
import Testing

struct LunarCalculatorTests {
	/// Reference times are quoted in UT and the search windows are built from calendar
	/// components, so both have to be read in a calendar that agrees. Going through
	/// `Calendar.current` would fail on a runner whose region defaults to a non-Gregorian
	/// calendar even though the calculator is correct — the same guard
	/// `SolsticeCalculatorTests` documents.
	private static let utcGregorian: Calendar = {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
		return calendar
	}()

	private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day
		components.hour = hour
		components.minute = minute
		return utcGregorian.date(from: components) ?? .distantPast
	}

	private static let london = CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276)
	private static let utc = TimeZone(identifier: "UTC") ?? .gmt

	private func minutes(between first: Date, and second: Date) -> Double {
		abs(first.timeIntervalSince(second)) / 60
	}

	// MARK: - The ephemeris, against the book

	/// Meeus example 47.a. This is the whole lunar series pinned in one assertion — it was
	/// only ever checked indirectly before the extraction.
	@Test("Lunar position matches Meeus example 47.a")
	func lunarPositionMatchesMeeus() {
		let (longitude, latitude, distance) = Ephemeris.lunarPosition(jde: 2_448_724.5)

		#expect(abs(longitude - 133.162655) < 0.000001)
		#expect(abs(latitude - -3.229126) < 0.000001)
		#expect(abs(distance - 368_409.7) < 0.1)
	}

	/// Meeus example 25.b. The radius vector uses the lower-precision method, so it is
	/// held to a looser bound than the longitude.
	@Test("Solar position matches Meeus example 25.b")
	func solarPositionMatchesMeeus() {
		let (longitude, distance) = Ephemeris.solarPosition(jde: 2_448_908.5)

		#expect(abs(longitude - 199.90987) < 0.0001)
		#expect(abs(distance - 0.99760775) < 0.0001)
	}

	/// Meeus example 48.a, for the same instant as 47.a. The example is quoted at 00:00
	/// TD; a `Date` at 00:00 UT is about 59 seconds earlier in 1992, which moves the
	/// fraction by under 0.0001.
	@Test("Illuminated fraction matches Meeus example 48.a")
	func illuminatedFractionMatchesMeeus() {
		let moon = LunarCalculator.moon(
			for: Self.date(1992, 4, 12),
			coordinate: Self.london,
			timeZone: Self.utc
		)

		#expect(abs(moon.illuminatedFraction - 0.6786) < 0.001)
		#expect(moon.phase == .waxingGibbous)
	}

	// MARK: - Rising and setting

	/// The check that catches the mistake this solver is most likely to make. Meeus's
	/// `h₀ = 0.7275·π − 34′` is for geocentric positions; applying it to the topocentric
	/// ones the ephemeris returns would double-count parallax and shift moonrise by well
	/// over an hour. At full moon the moon rises as the sun sets, so an error of that size
	/// is impossible to miss here.
	@Test("The full moon rises as the sun sets")
	func fullMoonRisesAtSunset() throws {
		let fullMoon = try #require(
			LunarCalculator.nextPhaseEvent(.full, after: Self.date(2026, 8, 1))
		)

		let moon = LunarCalculator.moon(for: fullMoon, coordinate: Self.london, timeZone: Self.utc)
		let moonrise = try #require(moon.moonrise)

		let solar = try #require(NTSolar(
			for: moonrise,
			coordinate: Self.london,
			timeZone: Self.utc
		))

		// Within half an hour of sunset — the two are not exactly simultaneous, since the
		// moon is a little off the ecliptic and refraction differs slightly.
		#expect(minutes(between: moonrise, and: solar.safeSunset) < 30)
	}

	@Test("Moonrise and moonset bracket the moon being above the horizon")
	func crossingsGoTheRightWay() throws {
		let moon = LunarCalculator.moon(
			for: Self.date(2026, 8, 14),
			coordinate: Self.london,
			timeZone: Self.utc
		)

		let moonrise = try #require(moon.moonrise)
		let moonset = try #require(moon.moonset)

		let beforeRise = LunarCalculator.altitude(at: moonrise.addingTimeInterval(-600), coordinate: Self.london)
		let afterRise = LunarCalculator.altitude(at: moonrise.addingTimeInterval(600), coordinate: Self.london)
		#expect(beforeRise < afterRise)

		let beforeSet = LunarCalculator.altitude(at: moonset.addingTimeInterval(-600), coordinate: Self.london)
		let afterSet = LunarCalculator.altitude(at: moonset.addingTimeInterval(600), coordinate: Self.london)
		#expect(beforeSet > afterSet)
	}

	/// The moon rises about fifty minutes later each day, so roughly once a lunation a
	/// calendar day has no moonrise — or no moonset. Ordinary, and the UI has to cope.
	@Test("A day with no moonset still reports a moonrise")
	func dayWithoutMoonset() {
		let moon = LunarCalculator.moon(
			for: Self.date(2026, 8, 23),
			coordinate: Self.london,
			timeZone: Self.utc
		)

		#expect(moon.moonrise != nil)
		#expect(moon.moonset == nil)
	}

	@Test("A day with no moonrise still reports a moonset")
	func dayWithoutMoonrise() {
		let moon = LunarCalculator.moon(
			for: Self.date(2026, 9, 6),
			coordinate: Self.london,
			timeZone: Self.utc
		)

		#expect(moon.moonrise == nil)
		#expect(moon.moonset != nil)
	}

	// MARK: - Phases

	/// Solar eclipses only happen at new moon, so the phase search and the eclipse search
	/// — written independently of one another — have to agree about when this one is. They
	/// are not measuring quite the same thing: conjunction in ecliptic longitude is not
	/// the instant of greatest eclipse for a particular observer, which is why the bound
	/// is half an hour rather than seconds.
	@Test("The phase search agrees with the eclipse search about the 2026 new moon")
	func newMoonAgreesWithEclipse() throws {
		let newMoon = try #require(
			LunarCalculator.nextPhaseEvent(.new, after: Self.date(2026, 8, 1))
		)

		let eclipse = try #require(EclipseCalculator.eclipses(
			at: CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426),
			from: Self.date(2026, 8, 1),
			through: Self.date(2026, 8, 31),
			minimumObscuration: 0
		).first)

		#expect(minutes(between: newMoon, and: eclipse.maximum) < 30)
	}

	@Test("Successive full moons are a synodic month apart")
	func fullMoonsAreALunationApart() throws {
		var date = Self.date(2026, 8, 1)
		var intervals: [Double] = []

		for _ in 0 ..< 4 {
			let full = try #require(LunarCalculator.nextPhaseEvent(.full, after: date))
			if date != Self.date(2026, 8, 1) {
				intervals.append(full.timeIntervalSince(date) / 86400)
			}
			date = full
		}

		// The synodic month is 29.53 days on average and varies by about half a day.
		#expect(intervals.allSatisfy { $0 > 29.0 && $0 < 30.1 })
	}

	@Test("Illumination peaks at full moon and bottoms at new")
	func illuminationTracksPhase() throws {
		let full = try #require(LunarCalculator.nextPhaseEvent(.full, after: Self.date(2026, 8, 1)))
		let new = try #require(LunarCalculator.nextPhaseEvent(.new, after: Self.date(2026, 8, 1)))

		let atFull = LunarCalculator.moon(for: full, coordinate: Self.london, timeZone: Self.utc)
		let atNew = LunarCalculator.moon(for: new, coordinate: Self.london, timeZone: Self.utc)

		#expect(atFull.illuminatedFraction > 0.99)
		#expect(atFull.phase == .full)
		#expect(atNew.illuminatedFraction < 0.01)
		#expect(atNew.phase == .new)
	}

	/// Walking a whole lunation should pass through all eight phases in order, and the
	/// waxing half should come before the waning half.
	@Test("A lunation passes through every phase in order")
	func lunationCoversEveryPhase() throws {
		let new = try #require(LunarCalculator.nextPhaseEvent(.new, after: Self.date(2026, 8, 1)))

		var seen: [LunarCalculator.Phase] = []
		for hour in stride(from: 0.0, to: 29.5 * 24, by: 6) {
			let moon = LunarCalculator.moon(
				for: new.addingTimeInterval(hour * 3600),
				coordinate: Self.london,
				timeZone: Self.utc
			)
			if seen.last != moon.phase {
				seen.append(moon.phase)
			}
		}

		let expected: [LunarCalculator.Phase] = [
			.new, .waxingCrescent, .firstQuarter, .waxingGibbous,
			.full, .waningGibbous, .lastQuarter, .waningCrescent,
		]

		#expect(seen.prefix(expected.count) == ArraySlice(expected))
		#expect(expected.prefix(4).allSatisfy(\.isWaxing))
		#expect(expected.suffix(4).allSatisfy { !$0.isWaxing })
	}

	// MARK: - Invariants

	@Test("Distance stays within the moon's real range")
	func distanceIsPlausible() {
		for day in stride(from: 0, to: 60, by: 3) {
			let moon = LunarCalculator.moon(
				for: Self.date(2026, 8, 1).addingTimeInterval(Double(day) * 86400),
				coordinate: Self.london,
				timeZone: Self.utc
			)

			// Perigee and apogee bracket roughly 356,500 to 406,700 km.
			#expect(moon.distance > 355_000 && moon.distance < 408_000)
		}
	}

	@Test("Repeated queries agree")
	func repeatedQueriesAgree() {
		let first = LunarCalculator.moon(for: Self.date(2026, 8, 14), coordinate: Self.london, timeZone: Self.utc)
		let second = LunarCalculator.moon(for: Self.date(2026, 8, 14), coordinate: Self.london, timeZone: Self.utc)

		#expect(first == second)
	}
}
