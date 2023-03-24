//
//  EarthScene.swift
//  Solstice
//
//  Created by Daniel Eden on 24/03/2023.
//

import SceneKit
import SpriteKit

var earthScene: SCNScene? {
	let scene = SCNScene()
	
	let earthNode = EarthNode()
	let tiltNode = SCNNode()
	
	let isSummer = true
	let tiltAngle = isSummer ? 23.4 : -23.4
	
	tiltNode.eulerAngles = SCNVector3(tiltAngle * (.pi / 180.0), .pi / 2, 0)
	tiltNode.addChildNode(earthNode)
	scene.rootNode.addChildNode(tiltNode)
	
	// Create a strong light
	let light = SCNLight()
	light.type = .omni
	light.temperature = 6300
	light.intensity = 5000
	light.castsShadow = true
	light.shadowSampleCount = 16
	light.shadowBias = 2
	light.shadowRadius = 10
	
	let lightNode = SCNNode()
	lightNode.light = light
	lightNode.position = SCNVector3(-50, 0, 0)
	
	scene.rootNode.addChildNode(lightNode)
	
	return scene
}
