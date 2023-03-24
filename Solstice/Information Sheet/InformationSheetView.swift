//
//  InformationSheetView.swift
//  Solstice
//
//  Created by Daniel Eden on 22/03/2023.
//

import SwiftUI
import SceneKit

#if canImport(UIKit)
typealias NativeViewRepresentable = UIViewRepresentable
typealias NativeColor = UIColor
#elseif canImport(AppKit)
typealias NativeViewRepresentable = NSViewRepresentable
typealias NativeColor = NSColor
#endif

fileprivate enum Event: String, CaseIterable {
	case marchEquinox = "March Equinox",
			 juneSolstice = "June Solstice",
			 septemberEquinox = "September Equinox",
			 decemberSolstice = "December Solstice"
	
	var shortName: String {
		self.rawValue.split(separator: /\ /).first?.capitalized ?? ""
	}
}

struct InformationSheetView: View {
	@State var scene: SCNScene? = earthScene
	@State fileprivate var event: Event = .juneSolstice
	
	var body: some View {
		GeometryReader { geometry in
			Form {
				Section {
					Picker(selection: $event) {
						ForEach(Event.allCases, id: \.self) { eventName in
							ViewThatFits {
								Text(eventName.rawValue)
								Text(eventName.shortName)
							}
						}
					} label: {
						Text("View:")
					}
					.pickerStyle(.segmented)
					
					CustomSceneView(scene: $scene)
						.frame(height: min(geometry.size.width, 400))
					
					Text("The equinox and solstice define the transitions between the seasons of the astronomical calendar and are a key part of the Earth’s orbit around the Sun.")
					
					VStack(alignment: .leading) {
						Text("Equinox")
							.font(.headline)
						Text("The equinox occurs twice a year, in March and September, and mark the points when the Sun crosses the equator’s path. During the equinox, day and night are around the same length all across the globe.")
					}
					
					VStack(alignment: .leading) {
						Text("Solstice")
							.font(.headline)
						Text("The solstice occurs twice a year, in June and December (otherwise known as the summer and winter solstices), and mark the sun’s northernmost and southernmost excursions. During the June solstice, the Earth’s northern hemisphere is pointed towards the sun, resulting in increased sunlight and warmer temperatures; the same is true for the southern hemisphere during the December solstice.")
					}
					
				} footer: {
					Text("3D Model Source: [NASA Visualization Technology Applications and Development](https://solarsystem.nasa.gov/resources/2393/earth-3d-model/)")
				}
			}
			.formStyle(.grouped)
			.navigationTitle("Equinox and Solstice")
			.onChange(of: event) { newValue in
				var angle: CGFloat
				switch newValue {
				case .marchEquinox:
					angle = -.pi / 2
				case .juneSolstice:
					angle = 0
				case .septemberEquinox:
					angle = .pi / 2
				case .decemberSolstice:
					angle = .pi
				}
				
				let action = SCNAction.rotateTo(
					x: 0,
					y: angle,
					z: 0,
					duration: 1,
					usesShortestUnitArc: true
				)
				
				action.timingMode = .easeOut
				
				if let node = scene?.rootNode.childNode(withName: "Sun Container", recursively: true) {
					node.runAction(action)
				}
			}
		}
	}
}

struct InformationSheetView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			InformationSheetView()
		}
	}
}

struct CustomSceneView: NativeViewRepresentable {
	@Binding var scene: SCNScene?
	
	func makeView(context: Context) -> SCNView {
		let view = SCNView()
		view.autoenablesDefaultLighting = false
		view.antialiasingMode = .multisampling2X
		view.backgroundColor = .clear
		
		let node = scene?.rootNode
		
		node?.rotation = .init(0, 0, 90, 0)
		view.scene = scene
		
		let bloomFilter = CIFilter(name:"CIBloom")!
		bloomFilter.setValue(0.2, forKey: "inputIntensity")
		bloomFilter.setValue(4.0, forKey: "inputRadius")
		scene?.rootNode.filters = [bloomFilter]
		
		return view
	}
	
	func updateView(_ uiView: SCNView, context: Context) {
		
	}
	
	#if canImport(UIKit)
	func makeUIView(context: Context) -> SCNView {
		makeView(context: context)
	}
	
	func updateUIView(_ uiView: SCNView, context: Context) {
		updateView(uiView, context: context)
	}
	#elseif canImport(AppKit)
	func makeNSView(context: Context) -> SCNView {
		makeView(context: context)
	}
	
	func updateNSView(_ nsView: SCNView, context: Context) {
		updateView(nsView, context: context)
	}
	#endif
}
