//
//  GetSolarNoon.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct GetSolarNoon: AppIntent {
	static var title: LocalizedStringResource = "Get Solar Noon"
	static var description = IntentDescription("Returns the time at which the sun crosses the local meridian (solar noon) on the given date.")

	@Parameter(title: "Date")
	var date: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get solar noon on \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Date?> {
		let evaluationDate = date ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)

		let solar = NTSolar(for: evaluationDate, coordinate: coordinate, timeZone: timeZone)
		return .result(value: solar?.solarNoon)
	}
}
