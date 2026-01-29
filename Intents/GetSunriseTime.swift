//
//  GetSunriseTime.swift
//  Solstice
//
//  Created by Daniel Eden on 01/03/2023.
//

import Foundation
import AppIntents
import CoreLocation
import SunKit

struct GetSunriseTime: AppIntent {
	static var title: LocalizedStringResource = "Get Sunrise Time"
	static var description = IntentDescription("Calculate the sunrise time on a given date in a given location")

	@Parameter(title: "Date")
	var date: Date

	@Parameter(title: "Location")
	var location: CLPlacemark

	static var parameterSummary: some ParameterSummary {
		Summary("Get the sunrise time on \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Date?> & ProvidesDialog {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the sunrise for?")
		}

		let sun = Sun(for: date, coordinate: coordinate)

		return .result(
			value: sun.sunrise,
			dialog: "\((sun.sunrise ?? date).formatted(date: .omitted, time: .shortened))"
		)
	}
}

extension GetSunriseTime: CustomIntentMigratedAppIntent {
	static var intentClassName = "GetSunriseTimeIntent"
}
