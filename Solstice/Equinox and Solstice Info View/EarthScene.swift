//
//  EarthScene.swift
//  Solstice
//
//  Created by Daniel Eden on 24/03/2023.
//

import SceneKit
import SpriteKit

#if os(iOS)
typealias SKFloat = Float
#elseif os(macOS)
typealias SKFloat = CGFloat
#endif

class EarthScene: SCNScene {
	var lightAnchorNode: SCNNode?
	var earthNode: SCNNode = EarthNode()
	
	public override init() {
		super.init()
		build()
	}
	
	public init(earthNode: EarthNode = EarthNode()) {
		super.init()
		self.earthNode = earthNode
		build()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		build()
	}
	
	func build() {
		let tiltNode = SCNNode()
		
		tiltNode.eulerAngles = SCNVector3(-23.4 * (.pi / 180.0), .pi / 2, 0)
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
		lightNode.position = SCNVector3(-100, 2, 0)
		
		self.lightAnchorNode = SCNNode()
		self.lightAnchorNode?.addChildNode(lightNode)
		
		self.rootNode.addChildNode(self.lightAnchorNode!)
	}
	
	func simulateDate(_ date: Date) {
		guard let yearRange = calendar.dateInterval(of: .year, for: date) else {
			return
		}
		
		let yearStart = yearRange.start.timeIntervalSinceReferenceDate
		let yearEnd = yearRange.end.timeIntervalSinceReferenceDate
		let yearProgress = (date.timeIntervalSinceReferenceDate - yearStart) / (yearEnd - yearStart)
		let lightRotation = .pi * 2 * yearProgress
		
		self.lightAnchorNode?.eulerAngles = SCNVector3(x: 0, y: SKFloat(lightRotation - .pi), z: 0)
		self.earthNode.eulerAngles = earthRotationAmount(for: date)
	}
	
	func earthRotationAmount(for date: Date = Date()) -> SCNVector3 {
		guard let dayRange = calendar.dateInterval(of: .day, for: date) else {
			return .init()
		}
		
		let dayStart = dayRange.start.timeIntervalSinceReferenceDate
		let dayEnd = dayRange.end.timeIntervalSinceReferenceDate
		let dayProgress = (date.timeIntervalSinceReferenceDate - dayStart) / (dayEnd - dayStart)
		let earthRotation = .pi * 2 * dayProgress
		return SCNVector3(x: 0, y: SKFloat(earthRotation - .pi / 2), z: 0)
	}
}
