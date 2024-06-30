//
//  SolarSystemMiniMap.swift
//  Solstice
//
//  Created by Daniel Eden on 28/06/2024.
//

import SwiftUI

struct SolarSystemMiniMap: View {
	var event: AnnualSolarEvent
	
	var angle: Double {
		event.sunAngle
	}
	
	var size: Double = 60
	
	var body: some View {
		HStack {
			VStack(alignment: .trailing, spacing: 0) {
				Text(event.shortMonthDescription)
					.fontWeight(.semibold)
				Text(event.shortEventDescription)
			}
			.font(.subheadline)
			
			ZStack {
				Circle()
					.strokeBorder(.tertiary, lineWidth: 3)
					.overlay(alignment: .trailing) {
						Circle()
							.fill(.primary)
							.frame(width: size / 6, height: size / 6)
							.offset(x: size / 20)
					}
					.rotationEffect(Angle(radians: angle) * -1)
				
				Circle()
					.fill(.primary)
					.frame(width: size / 4, height: size / 4)
			}
			.frame(width: size, height: size)
			.foregroundStyle(.secondary)
		}
		.padding()
		.foregroundStyle(.secondary)
	}
}

#Preview {
	SolarSystemMiniMap(event: .juneSolstice)
}
