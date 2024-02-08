//
//  EarthModelView.swift
//  Solstice
//
//  Created by Daniel Eden on 04/02/2024.
//

import SwiftUI
import RealityKit

#if os(visionOS)
struct EarthModelView: View {
	var body: some View {
		RealityView { content in
			if let earth = try? await Entity(named: "Earth") {
				content.add(earth)
				
				for animation in earth.availableAnimations {
					earth.playAnimation(animation)
				}
				
				
			}
		}
	}
}
#else
struct EarthModelView: View {
	var body: some View {
		EmptyView()
	}
}
#endif

#Preview {
    EarthModelView()
}
