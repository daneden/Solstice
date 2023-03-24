//
//  EarthScene.swift
//  Solstice
//
//  Created by Daniel Eden on 24/03/2023.
//

import SceneKit
import SpriteKit

class EarthScene: SCNScene {
	var lightAnchorNode: SCNNode?
	
	public override init() {
		super.init()
		build()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		build()
	}
	
	func build() {
		let earthNode = EarthNode()
		let tiltNode = SCNNode()
		
		tiltNode.eulerAngles = SCNVector3(23.4 * (.pi / 180.0), .pi / 2, 0)
		tiltNode.addChildNode(earthNode)
		self.rootNode.addChildNode(tiltNode)
		
		// Create a strong light
		let light = SCNLight()
		light.type = .omni
		light.temperature = 6200
		light.intensity = 5000
		light.castsShadow = true
		light.shadowSampleCount = 16
		light.shadowBias = 2
		light.shadowRadius = 10
		
		let lightNode = SCNNode()
		
		lightNode.light = light
		lightNode.position = SCNVector3(-50, 5, 0)
		
		self.lightAnchorNode = SCNNode()
		self.lightAnchorNode?.addChildNode(lightNode)
		
		self.rootNode.addChildNode(self.lightAnchorNode!)
	}
}
