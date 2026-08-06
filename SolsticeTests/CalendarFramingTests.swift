//
//  CalendarFramingTests.swift
//  SolsticeTests
//
//  Guards the boundary between the calendar a user reads and the calendar the solar maths
//  runs in. A region default of islamic-umalqura, persian or buddhist makes
//  `Calendar.autoupdatingCurrent` report a year number the astronomy cannot use, and — for
//  the lunar calendars only — a "year" that is not a season.
//

import Foundation
@testable import Solstice
import Testing

struct CalendarFramingTests {
	/// A fixed instant so nothing here drifts with the wall clock: 2026-06-01 12:00 UTC.
	private static let referenceDate = Date(timeIntervalSince1970: 1_780_315_200)

	private static let seasonal: [Calendar.Identifier] = [.gregorian, .persian, .buddhist, .hebrew]
	private static let lunar: [Calendar.Identifier] = [.islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura]

	private static func makeCalendar(_ identifier: Calendar.Identifier) -> Calendar {
		var calendar = Calendar(identifier: identifier)
		calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
		return calendar
	}

	@Test("Seasonal calendars pass through unchanged", arguments: seasonal)
	func seasonalCalendarsPassThrough(identifier: Calendar.Identifier) {
		#expect(Self.makeCalendar(identifier).seasonalEquivalent.identifier == identifier)
	}

	@Test("Lunar calendars are substituted for Gregorian", arguments: lunar)
	func lunarCalendarsAreSubstituted(identifier: Calendar.Identifier) {
		#expect(Self.makeCalendar(identifier).seasonalEquivalent.identifier == .gregorian)
	}

	/// How far the start of the year wanders through the solar year over `count` years,
	/// measured in Gregorian days.
	private func yearStartSpread(over count: Int, in calendar: Calendar) -> Int {
		var gregorian = Calendar(identifier: .gregorian)
		gregorian.timeZone = calendar.timeZone

		var starts: [Int] = []
		var probe = Self.referenceDate
		for _ in 0 ..< count {
			guard let year = calendar.dateInterval(of: .year, for: probe) else { break }
			starts.append(gregorian.ordinality(of: .day, in: .year, for: year.start) ?? 0)
			probe = year.end.addingTimeInterval(24 * 60 * 60)
		}

		return (starts.max() ?? 0) - (starts.min() ?? 0)
	}

	/// The property that actually separates a seasonal calendar from a lunar one — not the
	/// length of the year. A Hebrew year is 353–385 days and so is never a solar year, but
	/// its leap month pulls it back, and its start oscillates within a month rather than
	/// precessing. Measured over 12 years: Gregorian and Buddhist 0, Persian 1, Hebrew 27.
	@Test("Seasonal frames stay anchored to the seasons", arguments: seasonal + lunar)
	func seasonalFramesDoNotPrecess(identifier: Calendar.Identifier) {
		#expect(yearStartSpread(over: 12, in: Self.makeCalendar(identifier).seasonalEquivalent) <= 30)
	}

	/// The counterpart, and the reason the substitution exists: left alone, a lunar year has
	/// no correction and slides about 11 days earlier every year. Measured over 12 years,
	/// both Islamic variants wander 117 days — this is what put July at the head of the
	/// Arabic annual chart.
	@Test("Lunar frames precess when they are not substituted", arguments: lunar)
	func lunarFramesPrecess(identifier: Calendar.Identifier) {
		#expect(yearStartSpread(over: 12, in: Self.makeCalendar(identifier)) > 100)
	}

	/// A lunisolar leap year legitimately has 13 months, so the count is a range.
	@Test("Monthly sample dates cover one seasonal cycle", arguments: seasonal + lunar)
	func monthlySamplesCoverTheYear(identifier: Calendar.Identifier) throws {
		let calendar = Self.makeCalendar(identifier).seasonalEquivalent
		let dates = calendar.monthlySampleDates(inYearContaining: Self.referenceDate)

		#expect(dates.count == 12 || dates.count == 13)
		let first = try #require(dates.first)
		let last = try #require(dates.last)
		#expect(last.timeIntervalSince(first) >= 300 * 24 * 60 * 60)
	}

	/// Guards against a future edit quietly pointing the solar maths back at the user's
	/// calendar. `SolsticeCalculator` evaluates a polynomial over a proleptic Gregorian year.
	@Test("The solar calendar is Gregorian")
	func solarCalendarIsGregorian() {
		#expect(solarCalendar.identifier == .gregorian)
	}

	/// A canary against the real process calendar rather than a constructed one. It is inert
	/// wherever the process resolves to a Gregorian calendar — which includes a plain
	/// `xcodebuild test`, and `-testLanguage ar -testRegion SA`, neither of which changes the
	/// calendar preference. It bites on a device or runner whose region supplies a lunar one.
	@Test("The chart frame is seasonal under the process calendar")
	func processFrameIsSeasonal() {
		#expect(calendar.identifier == .gregorian, "TEMPORARY PROBE")
		#expect(
			yearStartSpread(over: 12, in: calendar.seasonalEquivalent) <= 30,
			"the process calendar \(calendar.identifier) did not yield a seasonal frame"
		)
	}

	@Test("The next solstice after 1 June 2026 is the June 2026 solstice")
	func nextSolsticeResolvesCorrectly() throws {
		var gregorian = Calendar(identifier: .gregorian)
		gregorian.timeZone = try #require(TimeZone(identifier: "UTC"))

		let components = gregorian.dateComponents([.year, .month, .day], from: Self.referenceDate.nextSolstice)
		#expect(components.year == 2026)
		#expect(components.month == 6)
		#expect(components.day == 21)
	}
}
