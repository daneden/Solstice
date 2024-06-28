//
//  SolarSystemMiniMap.swift
//  Solstice
//
//  Created by Daniel Eden on 28/06/2024.
//

import SwiftUI

struct SolarSystemMiniMap: View {
	var angle: CGFloat = 0
	var size: Double = 60
	
	var body: some View {
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
}

#Preview {
    SolarSystemMiniMap()
}
