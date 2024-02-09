//
//  EarthModelView.swift
//  Solstice
//
//  Created by Daniel Eden on 04/02/2024.
//

import SwiftUI
import RealityKit
import ARKit

#if canImport(UIKit)
typealias NativeViewRepresentable = UIViewRepresentable
typealias NativeColor = UIColor
#elseif canImport(AppKit)
typealias NativeViewRepresentable = NSViewRepresentable
typealias NativeColor = NSColor
#endif

#if os(visionOS)
struct EarthModelView: View {
	@State var rotationAmount: Double = .pi / 2
	var body: some View {
		RealityView { content in
			if let earth = try? await Entity(named: "Earth") {
				content.add(earth)
				
				for animation in earth.availableAnimations {
					earth.playAnimation(animation)
				}
			}
		} update: { content in
			guard let earth = content.entities.first else {
				return
			}
			
			var transform = earth.transform
			transform.rotation = .init(angle: Float(Angle(radians: rotationAmount).radians), axis: .init(x: 0, y: 1, z: 0))
			earth.transform = transform
		}
	}
}
#else
struct EarthModelView: View {
	@State var rotationAmount: Double = .pi / 2
	#if os(iOS)
	let resourceRequest = NSBundleResourceRequest(tags: ["earth"])
	#endif
	@State var scene: EarthScene?
	var body: some View {
		VStack {
			if scene != nil {
				CustomSceneView(scene: $scene)
					.frame(maxHeight: .infinity)
			} else {
				#if os(iOS)
				HStack {
					Spacer()
					ProgressView(value: resourceRequest.progress.fractionCompleted, total: 1.0) {
						Text("Loading...")
					}
					.progressViewStyle(.circular)
					Spacer()
				}
				.frame(maxHeight: .infinity)
				#endif
			}
		}
		.onChange(of: rotationAmount) {
			let action = SCNAction.rotateTo(
				x: 0,
				y: rotationAmount,
				z: 0,
				duration: 1,
				usesShortestUnitArc: true
			)
			
			action.timingMode = .easeOut
			
			if let node = scene?.lightAnchorNode {
				node.runAction(action)
			}
		}
		.task {
			#if os(iOS)
			if await !resourceRequest.conditionallyBeginAccessingResources() {
				do {
					try await resourceRequest.beginAccessingResources()
				} catch {
					print(error)
				}
			}
			#endif
			
			scene = EarthScene()
		}
		#if os(iOS)
		.onDisappear {
			resourceRequest.endAccessingResources()
		}
		#endif
	}
}
#endif

struct CustomSceneView<Scene: SCNScene>: NativeViewRepresentable {
	@Binding var scene: Scene?
	
	func makeView(context: Context) -> SCNView {
		let view = SCNView()
		view.autoenablesDefaultLighting = false
		view.backgroundColor = .clear
		
		let node = scene?.rootNode
		
		node?.rotation = .init(0, 0, 90, 0)
		view.scene = scene
		
		view.pointOfView?.camera?.fieldOfView = 35
		
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

#Preview {
	EarthModelView()
}
