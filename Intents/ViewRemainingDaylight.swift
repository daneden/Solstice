//
//  ViewRemainingDaylight.swift
//  Solstice
//
//  Created by Daniel Eden on 01/03/2023.
//

import Foundation
import AppIntents
import SunKit
import CoreLocation

struct ViewRemainingDaylight: AppIntent {
	static var title: LocalizedStringResource = "View Remaining Daylight"
	static var description = IntentDescription("View how much daylight is remaining today, based on the time until sunset.")

	@Parameter(title: "Location")
	var location: CLPlacemark

	static var parameterSummary: some ParameterSummary {
		Summary("Get today's remaining daylight in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<TimeInterval> & ProvidesDialog {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the daylight for?")
		}

		let sun = Sun(coordinate: coordinate)

		var resultValue: TimeInterval

		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		formatter.allowedUnits = [.hour, .minute, .second]

		if (sun.safeSunrise...sun.safeSunset).contains(.now) {
			resultValue = sun.safeSunset.timeIntervalSince(Date())
			return .result(
				value: resultValue,
				dialog: "\(formatter.string(from: resultValue) ?? "") of daylight left today"
			)
		} else if sun.safeSunset < .now {
			resultValue = 0
			return .result(
				value: resultValue,
				dialog: "No daylight left today. The sun set \(formatter.string(from: Date.now.timeIntervalSince(sun.safeSunset)) ?? "") ago."
			)
		} else if sun.safeSunrise > .now {
			resultValue = sun.daylightDuration
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
