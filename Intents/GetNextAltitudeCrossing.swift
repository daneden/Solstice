//
//  GetNextAltitudeCrossing.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

struct GetNextAltitudeCrossing: AppIntent {
	static var title: LocalizedStringResource = "Get Next Sun Altitude Crossing"
	static var description = IntentDescription("Returns the next time in the following 24 hours that the sun's altitude crosses a given value in a given direction (rising, falling, or either). Returns no value if no such crossing occurs.")

	@Parameter(title: "Altitude")
	var altitude: Measurement<UnitAngle>

	@Parameter(title: "Direction", default: .either)
	var direction: AltitudeCrossingDirection

	@Parameter(title: "Start Date")
	var startDate: Date?

	@Parameter(title: "Location")
	var location: LocationAppEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Next time sun altitude crosses \(\.$altitude) (\(\.$direction)) after \(\.$startDate) in \(\.$location)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<Date?> {
		let start = startDate ?? .now
		let (coordinate, timeZone) = try await resolveSunGeometryLocation(location)
		let targetDegrees = altitude.converted(to: .degrees).value

		let crossing = findNextAltitudeCrossing(
			targetDegrees: targetDegrees,
			direction: direction,
			start: start,
			coordinate: coordinate,
			timeZone: timeZone
		)

		return .result(value: crossing)
	}
}
