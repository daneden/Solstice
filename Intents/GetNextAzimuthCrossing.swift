//
//  GetNextAzimuthCrossing.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct GetNextAzimuthCrossing: AppIntent {
	static var title: LocalizedStringResource = "Get Next Sun Azimuth Crossing"
	static var description = IntentDescription("Returns the next time in the following 24 hours that the sun's azimuth (compass bearing) crosses a given value in a given direction (clockwise, counterclockwise, or either). Returns no value if no such crossing occurs.")

	@Parameter(title: "Azimuth", description: "The compass bearing in degrees for the sun's azimuth to cross.")
	var azimuth: Measurement<UnitAngle>

	@Parameter(title: "Direction", default: .either)
	var direction: AzimuthCrossingDirection

	@Parameter(title: "Start Date")
	var startDate: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Next time sun azimuth crosses \(\.$azimuth) (\(\.$direction)) after \(\.$startDate) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Date?> {
		let start = startDate ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)
		let targetDegrees = azimuth.converted(to: .degrees).value

		let crossing = findNextAzimuthCrossing(
			targetDegrees: targetDegrees,
			direction: direction,
			start: start,
			coordinate: coordinate,
			timeZone: timeZone
		)

		return .result(value: crossing)
	}
}
