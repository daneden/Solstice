//
//  GetSunsetTime.swift
//  Solstice
//
//  Created by Daniel Eden on 01/03/2023.
//

import Foundation
import AppIntents
import CoreLocation
import Solar

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
	
	func perform() async throws -> some ReturnsValue & ProvidesDialog {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the sunset for?")
		}
		
		let solar = Solar(for: date, coordinate: coordinate)
		
		return .result(value: solar?.sunset, dialog: "\((solar?.sunset ?? date).formatted(date: .omitted, time: .shortened))")
	}
}

extension GetSunsetTime: CustomIntentMigratedAppIntent {
	static var intentClassName = "GetSunsetTimeIntent"
}
