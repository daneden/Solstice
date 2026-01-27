//
//  SolsticeCalculatorTests.swift
//  SolsticeTests
//
//  Created with Swift Testing framework
//

import Testing
import Foundation
@testable import Solstice

struct SolsticeCalculatorTests {
	// MARK: - Known astronomical dates for validation
	// Reference values from the US Naval Observatory / timeanddate.com

	@Test("June solstice 2024 falls on June 20")
	func juneSolstice2024() {
		let solstice = SolsticeCalculator.juneSolstice(year: 2024)
		let components = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: solstice)

		#expect(components.month == 6)
		#expect(components.day == 20)
		#expect(components.year == 2024)
	}

	@Test("December solstice 2024 falls on December 21")
	func decemberSolstice2024() {
		let solstice = SolsticeCalculator.decemberSolstice(year: 2024)
		let components = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: solstice)

		#expect(components.month == 12)
		#expect(components.day == 21)
		#expect(components.year == 2024)
	}

	@Test("March equinox 2024 falls on March 20")
	func marchEquinox2024() {
		let equinox = SolsticeCalculator.marchEquinox(year: 2024)
		let components = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: equinox)

		#expect(components.month == 3)
		#expect(components.day == 20)
		#expect(components.year == 2024)
	}

	@Test("September equinox 2024 falls on September 22")
	func septemberEquinox2024() {
		let equinox = SolsticeCalculator.septemberEquinox(year: 2024)
		let components = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: equinox)

		#expect(components.month == 9)
		#expect(components.day == 22)
		#expect(components.year == 2024)
	}

	// MARK: - Cross-year consistency

	@Test("Solstices and equinoxes are calculated for multiple years", arguments: [2020, 2021, 2022, 2023, 2024, 2025, 2026])
	func eventsReturnValidDates(year: Int) {
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		let marchEquinox = SolsticeCalculator.marchEquinox(year: year)
		let septemberEquinox = SolsticeCalculator.septemberEquinox(year: year)

		let juneSolsticeComponents = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: juneSolstice)
		let decemberSolsticeComponents = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: decemberSolstice)
		let marchEquinoxComponents = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: marchEquinox)
		let septemberEquinoxComponents = Calendar.current.dateComponents(in: TimeZone(identifier: "UTC")!, from: septemberEquinox)

		// June solstice should be in June (day 20 or 21)
		#expect(juneSolsticeComponents.month == 6)
		#expect((20...21).contains(juneSolsticeComponents.day!))

		// December solstice should be in December (day 21 or 22)
		#expect(decemberSolsticeComponents.month == 12)
		#expect((21...22).contains(decemberSolsticeComponents.day!))

		// March equinox should be in March (day 19-21)
		#expect(marchEquinoxComponents.month == 3)
		#expect((19...21).contains(marchEquinoxComponents.day!))

		// September equinox should be in September (day 22-23)
		#expect(septemberEquinoxComponents.month == 9)
		#expect((22...23).contains(septemberEquinoxComponents.day!))
	}

	// MARK: - Ordering

	@Test("Solar events occur in correct seasonal order within a year")
	func eventsAreInCorrectOrder() {
		let year = 2024
		let march = SolsticeCalculator.marchEquinox(year: year)
		let june = SolsticeCalculator.juneSolstice(year: year)
		let september = SolsticeCalculator.septemberEquinox(year: year)
		let december = SolsticeCalculator.decemberSolstice(year: year)

		#expect(march < june)
		#expect(june < september)
		#expect(september < december)
	}

	// MARK: - Date extension tests

	@Test("recentSolstices returns a sorted array")
	func recentSolsticesAreSorted() {
		let date = Date()
		let solstices = date.recentSolstices

		for i in 1..<solstices.count {
			#expect(solstices[i - 1] <= solstices[i])
		}
	}

	@Test("recentEquinoxes returns a sorted array")
	func recentEquinoxesAreSorted() {
		let date = Date()
		let equinoxes = date.recentEquinoxes

		for i in 1..<equinoxes.count {
			#expect(equinoxes[i - 1] <= equinoxes[i])
		}
	}

	@Test("nextSolstice is in the future")
	func nextSolsticeIsInFuture() {
		let now = Date()
		#expect(now.nextSolstice > now)
	}

	@Test("nextEquinox is in the future")
	func nextEquinoxIsInFuture() {
		let now = Date()
		#expect(now.nextEquinox > now)
	}

	@Test("previousSolstice is in the past")
	func previousSolsticeIsInPast() {
		let now = Date()
		#expect(now.previousSolstice < now)
	}
}
