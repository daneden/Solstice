//
//  GetSunAzimuth.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct GetSunAzimuth: AppIntent {
	static var title: LocalizedStringResource = "Get Sun Azimuth"
	static var description = IntentDescription("Returns the sun's compass bearing (azimuth) in degrees, measured clockwise from true north. 0° = North, 90° = East, 180° = South, 270° = West.")

	@Parameter(title: "Date")
	var date: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get sun azimuth at \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Measurement<UnitAngle>> {
		let evaluationDate = date ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)

		guard let solar = NTSolar(for: evaluationDate, coordinate: coordinate, timeZone: timeZone) else {
			return .result(value: Measurement(value: 0, unit: .degrees))
		}

		let degrees = solar.azimuth(at: evaluationDate)
		return .result(value: Measurement(value: degrees, unit: .degrees))
	}
}
