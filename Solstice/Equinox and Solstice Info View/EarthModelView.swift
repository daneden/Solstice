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
	@State var realityViewContent: RealityViewContent?
	
	var body: some View {
		RealityView { content in
			if let earth = try? await Entity(named: "EarthScene") {
				content.add(earth)
				
				realityViewContent = content
			}
		}
		.task(id: realityViewContent?.entities.count) {
			guard let earthGroupRoot = realityViewContent?.entities.first,
						let earthGroup = earthGroupRoot.scene?.findEntity(named: "Group") else {
				return
			}
			
			var transform = earthGroup.transform
			transform.rotation *= simd_quatf(
				angle: Float(Angle(degrees: 180).radians),
				axis: SIMD3<Float>(0, 1, 0)
			)
			earthGroup.move(to: transform, relativeTo: nil, duration: 4, timingFunction: .linear)
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
