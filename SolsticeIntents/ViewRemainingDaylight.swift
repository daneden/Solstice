//
//  ViewRemainingDaylight.swift
//  Solstice
//
//  Created by Daniel Eden on 12/06/2022.
//

import Foundation
import AppIntents

struct ViewRemainingDaylight: AppIntent {
	static var title: LocalizedStringResource = "View Remaining Daylight"
	static var description = IntentDescription("View how much daylight is remaining today, based on the time until sunset.")

	static var parameterSummary: some ParameterSummary {
		Summary("Get the remaining daylight for your current location")
	}
	
	func perform() async throws -> some IntentResult {
		let calculator = SolarCalculator()
		let isDaytime = calculator.today.begins.isInPast && calculator.today.ends.isInFuture
		
		if isDaytime {
			return .result(value: Date().distance(to: calculator.today.ends))
		} else if calculator.today.ends.isInPast {
			return .result(value: TimeInterval(0))
		} else if calculator.today.begins.isInFuture {
			return .result(value: calculator.today.duration)
		} else {
			return .result(value: TimeInterval(0))
		}
	}
}

