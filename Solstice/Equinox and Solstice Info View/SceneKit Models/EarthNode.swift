//
//  EarthNode.swift
//  Solstice
//
//  Created by Daniel Eden on 24/03/2023.
//

import Foundation
import SceneKit
import SpriteKit

public class EarthNode : SCNNode {
	public override init() {
		super.init()
		build()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		build()
	}
	
	func build() {
		addBody()
		//addClouds()
		addPoles()
		addEquator()
		runAction(.rotate(by: .pi * 1.5, around: SCNVector3(x: 0, y: 1, z: 0), duration: 0))
		beginDailyRotation()
	}
	
	func addBody() {
		// Earth
		let bodyNode = SCNNode()
		
		let sphere = SCNSphere(radius: 1)
		sphere.segmentCount = 50
		
		let bodyMaterial = SCNMaterial()
		bodyMaterial.diffuse.contents = "Diffuse"
		bodyMaterial.specular.contents = "Specular"
		bodyMaterial.specular.intensity = 0.3
		bodyMaterial.emission.contents = "Emission"
		bodyMaterial.normal.contents = "Normal"
		bodyMaterial.normal.intensity = 0.75
		bodyMaterial.shininess = 0.30
		sphere.firstMaterial = bodyMaterial
		bodyNode.geometry = sphere
		addChildNode(bodyNode)
	}
	
	func addClouds() {
		// Clouds
		let atmosNode = SCNNode()
		let atmosSphere = SCNSphere(radius: 1.01)
		atmosSphere.segmentCount = 50
		
		let atmosMaterial = SCNMaterial()
		atmosMaterial.diffuse.contents = "Clouds"
		atmosMaterial.transparent.contents = "Clouds"
		atmosSphere.firstMaterial = atmosMaterial
		atmosNode.geometry = atmosSphere
		addChildNode(atmosNode)
		
		let action = SCNAction.rotate(by: .pi * -2, around: SCNVector3(x:0, y:1, z:0), duration: 360)
		let repeatAction = SCNAction.repeatForever(action)
		atmosNode.runAction(repeatAction)
	}
	
	func addPoles() {
		// Poles
		let poleNode = SCNNode()
		let pole = SCNCylinder(radius: 0.005, height: 2.2)
		poleNode.geometry = pole
		
		let poleMaterial = SCNMaterial()
		poleMaterial.emission.contents = SKColor.red
		poleMaterial.diffuse.contents = SKColor.red
		pole.firstMaterial = poleMaterial
		addChildNode(poleNode)
	}
	
	func addEquator() {
		// Equator
		let equatorNode = SCNNode()
		let equator = SCNCylinder(radius: 1.05, height: 0.01)
		equatorNode.geometry = equator
		
		let equatorMaterial = SCNMaterial()
		equatorMaterial.emission.contents = SKColor.systemOrange
		equatorMaterial.diffuse.contents = SKColor.systemOrange
		equator.firstMaterial = equatorMaterial
		addChildNode(equatorNode)
	}
	
	func beginDailyRotation() {
		let action = SCNAction.rotate(by: .pi * 2, around: SCNVector3(x:0, y:1, z:0), duration: 90)
		let repeatAction = SCNAction.repeatForever(action)
		runAction(repeatAction)
	}
}
