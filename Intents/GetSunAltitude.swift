//
//  GetSunAltitude.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct GetSunAltitude: AppIntent {
	static var title: LocalizedStringResource = "Get Sun Altitude"
	static var description = IntentDescription("Returns the sun's altitude above the horizon in degrees. Negative values mean the sun is below the horizon.")

	@Parameter(title: "Date")
	var date: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get sun altitude at \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Measurement<UnitAngle>> {
		let evaluationDate = date ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)

		guard let solar = NTSolar(for: evaluationDate, coordinate: coordinate, timeZone: timeZone) else {
			return .result(value: Measurement(value: 0, unit: .degrees))
		}

		let degrees = solar.altitude(at: evaluationDate)
		return .result(value: Measurement(value: degrees, unit: .degrees))
	}
}
