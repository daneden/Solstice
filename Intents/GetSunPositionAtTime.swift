//
//  GetSunPositionAtTime.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct GetSunPositionAtTime: AppIntent {
	static var title: LocalizedStringResource = "Get Sun Position"
	static var description = IntentDescription("Returns both the sun's altitude and azimuth at a given date and location, so downstream Shortcut actions can consume either as a magic variable.")

	@Parameter(title: "Date")
	var date: Date

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get sun position at \(\.$date) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<SunPositionEntity> {
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)

		guard let solar = NTSolar(for: date, coordinate: coordinate, timeZone: timeZone) else {
			return .result(value: SunPositionEntity())
		}

		let (altitude, azimuth) = solar.altitudeAndAzimuth(at: date)
		return .result(value: SunPositionEntity(altitudeDegrees: altitude, azimuthDegrees: azimuth))
	}
}
