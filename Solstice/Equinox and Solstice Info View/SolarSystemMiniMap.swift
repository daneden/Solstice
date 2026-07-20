//
//  SolarSystemMiniMap.swift
//  Solstice
//
//  Created by Daniel Eden on 28/06/2024.
//

import SwiftUI

struct SolarSystemMiniMap: View {
	var event: AnnualSolarEvent

	/// Explicit indicator rotation, so callers can drive it from an animated value.
	/// Falls back to the event's own angle for standalone use (e.g. previews).
	var rotation: Angle?

	var size: Double = 48

	private var indicatorRotation: Angle {
		rotation ?? Angle(radians: event.sunAngle) * -1
	}

	var body: some View {
		HStack {
			VStack(alignment: .trailing, spacing: 0) {
				Text(event.shortMonthDescription)
					.fontWeight(.semibold)
				Text(event.shortEventDescription)
			}
			.contentTransition(.numericText())
			.font(.caption)

			ZStack {
				Circle()
					.strokeBorder(.tertiary, lineWidth: 2)
					.padding(-1)
					.overlay(alignment: .trailing) {
						Image(systemName: "circle.lefthalf.filled.inverse")
							.resizable()
							.frame(width: size / 4, height: size / 4)
							.background {
								Circle()
									.fill(.background)
									.padding(-1)
							}
							.offset(x: size * 0.1)
					}
					.rotationEffect(indicatorRotation)

				Image(systemName: "sun.max.fill")
					.resizable()
					.frame(width: size / 2.5, height: size / 2.5)
			}
			.frame(width: size, height: size)
			.foregroundStyle(.secondary)
		}
		.foregroundStyle(.secondary)
	}
}

#Preview {
	SolarSystemMiniMap(event: .juneSolstice)
}
