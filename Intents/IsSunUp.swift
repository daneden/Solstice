//
//  IsSunUp.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct IsSunUp: AppIntent {
	static var title: LocalizedStringResource = "Is Sun Up"
	static var description = IntentDescription("Returns true if the sun is currently above the horizon at the given location.")

	@Parameter(title: "Date")
	var date: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Is the sun up at \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
		let evaluationDate = date ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)

		guard let solar = NTSolar(for: evaluationDate, coordinate: coordinate, timeZone: timeZone) else {
			return .result(value: false)
		}

		return .result(value: solar.altitude(at: evaluationDate) > 0)
	}
}
