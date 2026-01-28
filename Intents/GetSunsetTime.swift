//
//  GetSunsetTime.swift
//  Solstice
//
//  Created by Daniel Eden on 01/03/2023.
//

import Foundation
import AppIntents
import CoreLocation
import SunKit

struct GetSunsetTime: AppIntent {
	static var title: LocalizedStringResource = "Get Sunset Time"
	static var description = IntentDescription("Calculate the sunset time on a given date in a given location")

	@Parameter(title: "Date")
	var date: Date

	@Parameter(title: "Location")
	var location: CLPlacemark

	static var parameterSummary: some ParameterSummary {
		Summary("Get the sunset time on \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Date?> & ProvidesDialog {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the sunset for?")
		}

		let sun = Sun(for: date, coordinate: coordinate)

		return .result(
			value: sun.sunset,
			dialog: "\((sun.sunset ?? date).formatted(date: .omitted, time: .shortened))"
		)
	}
}

extension GetSunsetTime: CustomIntentMigratedAppIntent {
	static var intentClassName = "GetSunsetTimeIntent"
}
