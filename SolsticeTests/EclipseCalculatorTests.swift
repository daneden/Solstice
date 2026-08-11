//
//  EclipseCalculatorTests.swift
//  SolsticeTests
//
//  Reference circumstances come from NASA's eclipse catalogue and timeanddate.com.
//
//  Tolerances are set by what the underlying theory can deliver, not by what the
//  implementation happens to produce today:
//
//  - Contact times are allowed two minutes. Meeus's truncated lunar series is good to
//    about 10 arcseconds, and the moon closes on the sun at roughly half an arcsecond
//    per second, so half a minute of scatter is inherent.
//  - Obscuration is held to two percentage points.
//  - Duration of totality gets a much wider band. It depends on the difference between
//    two apparent radii that are within ~5% of each other, so the same small angular
//    uncertainty that leaves obscuration untouched moves the duration by several
//    percent. Anything tighter would be testing luck.
//

import CoreLocation
import Foundation
@testable import Solstice
import Testing

struct EclipseCalculatorTests {
	/// Reference values are quoted in UT, and the search window has to be built in a
	/// calendar that agrees. Reading these back through `Calendar.current` would fail on
	/// a runner whose region defaults to a non-Gregorian calendar even though the
	/// calculator itself is correct — the same hazard `SolsticeCalculatorTests` guards.
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

	/// Looks for an eclipse in the fortnight surrounding a known date, so a test failure
	/// means the circumstances are wrong rather than that the window was mistimed.
	private func eclipse(
		latitude: Double,
		longitude: Double,
		around year: Int,
		_ month: Int,
		_ day: Int,
		minimumObscuration: Double = 0
	) -> EclipseCalculator.LocalCircumstances? {
		let centre = Self.date(year, month, day)

		return EclipseCalculator.eclipses(
			at: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
			from: centre.addingTimeInterval(-7 * 86400),
			through: centre.addingTimeInterval(7 * 86400),
			minimumObscuration: minimumObscuration
		).first
	}

	private func minutes(between first: Date, and second: Date) -> Double {
		abs(first.timeIntervalSince(second)) / 60
	}

	// MARK: - Past eclipses, where the outcome is a matter of record

	/// The 2024 April 8 eclipse over North America. Dallas saw totality begin at about
	/// 13:40 CDT and last a little under four minutes, with the partial phase opening
	/// around 17:23 UT.
	@Test("Dallas sees totality at the 2024 April 8 eclipse")
	func dallas2024() throws {
		let circumstances = try #require(eclipse(latitude: 32.7767, longitude: -96.7970, around: 2024, 4, 8))

		#expect(circumstances.kind == .total)
		#expect(circumstances.obscuration == 1.0)
		#expect(circumstances.isCentral)
		#expect(minutes(between: circumstances.firstContact, and: Self.date(2024, 4, 8, 17, 23)) < 2)
		#expect(minutes(between: circumstances.maximum, and: Self.date(2024, 4, 8, 18, 42)) < 2)
		#expect(minutes(between: circumstances.lastContact, and: Self.date(2024, 4, 8, 20, 2)) < 2)

		// Published duration is 3m51s; the band reflects how sensitive this quantity is.
		let duration = try #require(circumstances.centralDuration)
		#expect(duration > 200 && duration < 270)
	}

	// MARK: - The eclipses this feature exists to announce

	@Test("Reykjavík is inside the path of the 2026 August 12 eclipse")
	func reykjavik2026() throws {
		let circumstances = try #require(eclipse(latitude: 64.1466, longitude: -21.9426, around: 2026, 8, 12))

		#expect(circumstances.kind == .total)
		#expect(circumstances.obscuration == 1.0)
		#expect(circumstances.magnitude > 1)
		#expect(try #require(circumstances.centralDuration) > 30)
		// Iceland catches this one low in the evening sky.
		#expect(circumstances.sunAltitudeAtMaximum > 0 && circumstances.sunAltitudeAtMaximum < 40)
	}

	/// The discriminating case: Madrid missed the 2026 path of totality by a hair. A
	/// calculator that is merely approximately right will call this one total.
	@Test("Madrid misses totality in 2026 despite near-complete coverage")
	func madrid2026() throws {
		let circumstances = try #require(eclipse(latitude: 40.4168, longitude: -3.7038, around: 2026, 8, 12))

		#expect(circumstances.kind == .partial)
		#expect(circumstances.centralDuration == nil)
		#expect(circumstances.obscuration > 0.97)
		#expect(circumstances.obscuration < 1.0)
	}

	@Test("London sees a deep partial eclipse in 2026")
	func london2026() throws {
		let circumstances = try #require(eclipse(latitude: 51.5072, longitude: -0.1276, around: 2026, 8, 12))

		#expect(circumstances.kind == .partial)
		#expect(abs(circumstances.obscuration - 0.91) < 0.02)
	}

	/// The longest totality over land this century — a little over six minutes at Luxor.
	@Test("Luxor sees more than six minutes of totality in 2027")
	func luxor2027() throws {
		let circumstances = try #require(eclipse(latitude: 25.6872, longitude: 32.6396, around: 2027, 8, 2))

		#expect(circumstances.kind == .total)
		let duration = try #require(circumstances.centralDuration)
		#expect(duration > 340 && duration < 420)
		// Near local noon in high summer, the sun is almost overhead.
		#expect(circumstances.sunAltitudeAtMaximum > 70)
	}

	@Test("Southern Spain sees an annular eclipse in 2028")
	func spain2028() throws {
		let circumstances = try #require(eclipse(latitude: 36.5271, longitude: -6.2886, around: 2028, 1, 26))

		#expect(circumstances.kind == .annular)
		#expect(circumstances.isCentral)
		// A ring means the moon never covers the whole disc, however well centred it is.
		#expect(circumstances.obscuration < 1.0)
		#expect(circumstances.magnitude < 1.0)
	}

	@Test("Sydney is inside the path of the 2028 July 22 eclipse")
	func sydney2028() throws {
		let circumstances = try #require(eclipse(latitude: -33.8688, longitude: 151.2093, around: 2028, 7, 22))

		#expect(circumstances.kind == .total)
		#expect(circumstances.obscuration == 1.0)
	}

	// MARK: - Places and times that should see nothing

	@Test(
		"Locations far from the 2026 path see no eclipse",
		arguments: [
			(-34.6037, -58.3816), // Buenos Aires
			(35.6762, 139.6503), // Tokyo
			(-33.8688, 151.2093), // Sydney
		]
	)
	func outsideThePath2026(latitude: Double, longitude: Double) {
		#expect(eclipse(latitude: latitude, longitude: longitude, around: 2026, 8, 12) == nil)
	}

	/// An eclipse happening while the sun is below the horizon isn't an eclipse to the
	/// person standing there. Tahiti is on the far side of the world from the 2027 event.
	@Test("An eclipse below the horizon is not reported")
	func belowTheHorizon() {
		#expect(eclipse(latitude: -17.6509, longitude: -149.4260, around: 2027, 8, 2) == nil)
	}

	@Test("A window with no eclipse returns nothing")
	func quietWindow() {
		let results = EclipseCalculator.eclipses(
			at: CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276),
			from: Self.date(2026, 9, 1),
			through: Self.date(2027, 2, 1),
			minimumObscuration: 0.1
		)

		#expect(results.isEmpty)
	}

	// MARK: - Invariants

	@Test("The obscuration threshold filters results")
	func thresholdFilters() {
		let coordinate = CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276)
		let from = Self.date(2026, 8, 5)
		let through = Self.date(2026, 8, 19)

		// London sees about 91% in 2026, so it passes a 90% bar but not a 95% one.
		#expect(!EclipseCalculator.eclipses(at: coordinate, from: from, through: through, minimumObscuration: 0.90).isEmpty)
		#expect(EclipseCalculator.eclipses(at: coordinate, from: from, through: through, minimumObscuration: 0.95).isEmpty)
	}

	@Test("Contacts bracket maximum and the sun is up throughout")
	func contactsAreOrdered() throws {
		let circumstances = try #require(eclipse(latitude: 51.5072, longitude: -0.1276, around: 2026, 8, 12))

		#expect(circumstances.firstContact < circumstances.maximum)
		#expect(circumstances.maximum < circumstances.lastContact)
		#expect(circumstances.sunAltitudeAtMaximum > -1)
	}

	/// Obscuration is an area and magnitude is a diameter, so for a partial eclipse the
	/// area hidden always trails the fraction of the diameter covered.
	@Test("Obscuration is below magnitude for a partial eclipse")
	func obscurationTrailsMagnitude() throws {
		let circumstances = try #require(eclipse(latitude: 51.5072, longitude: -0.1276, around: 2026, 8, 12))

		#expect(circumstances.kind == .partial)
		#expect(circumstances.obscuration < circumstances.magnitude)
	}

	@Test("Results are ordered and confined to the requested window")
	func resultsAreOrderedAndBounded() {
		let from = Self.date(2026, 1, 1)
		let through = Self.date(2029, 1, 1)

		let results = EclipseCalculator.eclipses(
			at: CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276),
			from: from,
			through: through,
			minimumObscuration: 0.1
		)

		#expect(results.count >= 2)
		#expect(results == results.sorted { $0.maximum < $1.maximum })
		#expect(results.allSatisfy { $0.maximum >= from && $0.maximum <= through })
		#expect(results.allSatisfy { $0.obscuration >= 0.1 })
	}

	/// When one disc is centred inside the other, both figures reduce to the ratio of the
	/// apparent radii — obscuration as its square, magnitude as itself. An annular
	/// eclipse is the only case where that relationship is visible in the output, since
	/// a total eclipse saturates obscuration at 1.
	@Test("Annular obscuration is the square of magnitude")
	func annularObscurationIsSquaredMagnitude() throws {
		let circumstances = try #require(eclipse(latitude: 36.5271, longitude: -6.2886, around: 2028, 1, 26))

		#expect(circumstances.kind == .annular)
		#expect(abs(circumstances.obscuration - pow(circumstances.magnitude, 2)) < 0.001)
	}

	/// Nothing in the calculator is seeded or cached, so the same query has to give the
	/// same answer — the detail view re-runs it on every location and date change.
	@Test("Repeated queries agree")
	func repeatedQueriesAgree() throws {
		let first = try #require(eclipse(latitude: 25.6872, longitude: 32.6396, around: 2027, 8, 2))
		let second = try #require(eclipse(latitude: 25.6872, longitude: 32.6396, around: 2027, 8, 2))

		#expect(first == second)
	}
}
