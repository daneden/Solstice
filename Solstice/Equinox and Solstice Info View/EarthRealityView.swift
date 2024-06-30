//
//  EarthRealityView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/06/2024.
//

import SwiftUI

import RealityKit
import RealityKitContent

struct EarthRealityView: View {
	@State var selection: AnnualSolarEvent = .juneSolstice
	
	var body: some View {
		VStack {
			Spacer()
			
			SolarSystemMiniMap(event: selection)
				.frame(maxWidth: .infinity, alignment: .trailing)
			
			RealityView { content in
				if let earth = try? await Entity(named: "Scene", in: realityKitContentBundle) {
					content.add(earth)
				}
			} update: { content in
				guard let rootEntity = content.entities.first,
							let earth = rootEntity.findEntity(named: "Earth"),
							var modelComponent = earth.components[ModelComponent.self],
							var shaderMaterial = modelComponent.materials.first as? ShaderGraphMaterial else {
					return
				}
				
				do {
					try shaderMaterial.setParameter(name: "Angle", value: .float(Float(Angle(radians: selection.sunAngle).degrees * -1)))
					modelComponent.materials = [shaderMaterial]
					earth.components.set(modelComponent)
				} catch {
					print(error)
				}
			}
			
			Spacer()
			
			Picker(selection: $selection.animation()) {
				ForEach(AnnualSolarEvent.allCases, id: \.self) { eventType in
					Text(eventType.shortMonthDescription)
				}
			} label: {
				Text("Month:")
			}
			.pickerStyle(.segmented)
		}
	}
}

#Preview {
    EarthRealityView()
}
