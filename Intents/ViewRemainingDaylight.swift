//
//  ViewRemainingDaylight.swift
//  Solstice
//
//  Created by Daniel Eden on 01/03/2023.
//

import Foundation
import AppIntents
import Solar
import CoreLocation

struct ViewRemainingDaylight: AppIntent {
	static var title: LocalizedStringResource = "View Remaining Daylight"
	static var description = IntentDescription("View how much daylight is remaining today, based on the time until sunset.")
	
	@Parameter(title: "Location")
	var location: CLPlacemark
	
	static var parameterSummary: some ParameterSummary {
		Summary("Get today's remaining daylight in \(\.$location)")
	}
	
	func perform() async throws -> some ReturnsValue & ProvidesDialog {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the daylight for?")
		}
		
		let solar = Solar(coordinate: coordinate)!
		let isDaytime = solar.safeSunrise < .now && solar.safeSunset > .now
		
		var resultValue: TimeInterval
		
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		formatter.allowedUnits = [.hour, .minute, .second]
		
		if isDaytime {
			resultValue = Date().distance(to: solar.safeSunset)
			return .result(
				value: resultValue,
				dialog: "\(formatter.string(from: resultValue) ?? "") of daylight left today"
			)
		} else if solar.safeSunset < .now {
			resultValue = 0
			return .result(
				value: resultValue,
				dialog: "No daylight left today. The sun set \(formatter.string(from: solar.safeSunset.distance(to: .now)) ?? "") ago."
			)
		} else if solar.safeSunrise > .now {
			resultValue = solar.daylightDuration
			return .result(
				value: resultValue,
				dialog: "\(formatter.string(from: resultValue) ?? "") of daylight left today"
			)
		} else {
			resultValue = 0
			return .result(
				value: resultValue,
				dialog: "\(formatter.string(from: resultValue) ?? "") of daylight left today"
			)
		}
	}
}

extension ViewRemainingDaylight: CustomIntentMigratedAppIntent {
	static var intentClassName = "ViewRemainingDaylightIntent"
}
