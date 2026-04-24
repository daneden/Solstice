//
//  IsSunOnBearing.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct IsSunOnBearing: AppIntent {
	static var title: LocalizedStringResource = "Is Sun Shining On Bearing"
	static var description = IntentDescription("Returns true if the sun is above the horizon and its azimuth is within a given tolerance of a compass bearing. Useful for automations like \"is the sun shining on my east-facing wall?\".")

	@Parameter(title: "Bearing", description: "Compass bearing of the surface in degrees (0 = North, 90 = East, 180 = South, 270 = West).")
	var bearing: Measurement<UnitAngle>

	@Parameter(title: "Tolerance", description: "Half-width of the angular window around the bearing.", default: Measurement(value: 60, unit: UnitAngle.degrees))
	var tolerance: Measurement<UnitAngle>

	@Parameter(title: "Date")
	var date: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Is the sun shining on bearing \(\.$bearing) (±\(\.$tolerance)) at \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
		let evaluationDate = date ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)

		guard let solar = NTSolar(for: evaluationDate, coordinate: coordinate, timeZone: timeZone) else {
			return .result(value: false)
		}

		let (altitude, azimuth) = solar.altitudeAndAzimuth(at: evaluationDate)
		guard altitude > 0 else {
			return .result(value: false)
		}

		let bearingDegrees = bearing.converted(to: .degrees).value
		let toleranceDegrees = abs(tolerance.converted(to: .degrees).value)
		let diff = signedAngularDifference(from: bearingDegrees, to: azimuth)
		return .result(value: abs(diff) <= toleranceDegrees)
	}
}
