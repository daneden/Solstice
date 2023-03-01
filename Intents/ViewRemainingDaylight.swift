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
	
	func perform() async throws -> some IntentResult {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the daylight for?")
		}
		
		let solar = Solar(coordinate: coordinate)!
		let isDaytime = solar.safeSunrise < .now && solar.safeSunset > .now
		
		if isDaytime {
			return .result(value: Date().distance(to: solar.safeSunset))
		} else if solar.safeSunset < .now {
			return .result(value: TimeInterval(0))
		} else if solar.safeSunrise > .now {
			return .result(value: solar.daylightDuration)
		} else {
			return .result(value: TimeInterval(0))
		}
	}
}

extension ViewRemainingDaylight: CustomIntentMigratedAppIntent {
	static var intentClassName = "ViewRemainingDaylightIntent"
}
