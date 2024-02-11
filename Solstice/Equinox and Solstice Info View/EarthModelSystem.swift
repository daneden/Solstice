//
//  EarthModelSystem.swift
//  Solstice
//
//  Created by Daniel Eden on 11/02/2024.
//

import Foundation
import RealityKit
#if canImport(Earth)
import Earth
#endif

class EarthModelSystem: System {
	private static let query = EntityQuery(where: .has(Earth.Is_EarthComponent.self))
	
	required init(scene: Scene) {
		
	}
	
	func update(context: SceneUpdateContext) {
		context.scene.performQuery(Self.query).forEach { entity in
			
		}
	}
}
