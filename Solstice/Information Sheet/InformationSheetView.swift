//
//  InformationSheetView.swift
//  Solstice
//
//  Created by Daniel Eden on 22/03/2023.
//

import SwiftUI
import SceneKit.ModelIO

struct InformationSheetView: View {
	@State var scene: SCNScene? = SCNScene(named: "Earth.scn")
	
	var body: some View {
		Form {
			CustomSceneView(scene: $scene)
				.frame(height: 500)
				.onAppear {
					let action = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 90))
					scene?.rootNode.childNode(withName: "Earth", recursively: true)?.runAction(action)
				}
		}
	}
}

struct InformationSheetView_Previews: PreviewProvider {
    static var previews: some View {
        InformationSheetView()
    }
}

struct CustomSceneView: UIViewRepresentable {
	@Binding var scene: SCNScene?
	
	func makeUIView(context: Context) -> SCNView {
		let view = SCNView()
		view.autoenablesDefaultLighting = true
		view.antialiasingMode = .multisampling2X
		view.backgroundColor = .clear
		
		let node = scene?.rootNode
		
		node?.rotation = .init(0, 0, 90, 0)
		view.scene = scene
		
		return view
	}
	
	func updateUIView(_ uiView: SCNView, context: Context) {
		
	}
}
