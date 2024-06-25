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
#elseif canImport(AppKit)
typealias NativeViewRepresentable = NSViewRepresentable
#endif

fileprivate struct Selection: Codable, Hashable {
	var event: Event = .solstice
	var equinoxMonth: EquinoxMonth = .march
	var solsticeMonth: SolsticeMonth = .june
	
	enum Event: CaseIterable, Codable {
		case equinox, solstice
		
		var description: LocalizedStringKey {
			switch self {
			case .equinox:
				return "Equinox"
			case .solstice:
				return "Solstice"
			}
		}
	}
	
	enum EquinoxMonth: CaseIterable, Codable {
		case march, september
		
		var description: LocalizedStringKey {
			switch self {
			case .march:
				return "March"
			case .september:
				return "September"
			}
		}
	}
	
	enum SolsticeMonth: CaseIterable, Codable {
		case june, december
		
		var description: LocalizedStringKey {
			switch self {
			case .june:
				return "June"
			case .december:
				return "December"
			}
		}
	}
	
	var sunAngle: CGFloat {
		switch event {
		case .equinox:
			return equinoxMonth == .march
				? -.pi / 2
				: .pi / 2
		case .solstice:
			return solsticeMonth == .june
			? 0
			: .pi
		}
	}
}

#if os(iOS)
extension NSBundleResourceRequest: @unchecked Sendable {}
#endif

struct EquinoxAndSolsticeInfoView: View {
	@State private var selection: Selection = Selection()
	#if os(iOS)
	let resourceRequest = NSBundleResourceRequest(tags: ["earth"])
	#endif
	@State var scene: EarthScene?
	
	var body: some View {
		GeometryReader { geometry in
			Form {
				Section {
					Group {
						if scene != nil {
							CustomSceneView(scene: $scene)
								.frame(height: min(geometry.size.width, 400))
								.transition(.opacity)
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
							.frame(height: min(geometry.size.width, 400))
#endif
						}
					}
					.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
					.listRowSeparator(.hidden)
					
					Picker(selection: $selection.event.animation()) {
						ForEach(Selection.Event.allCases, id: \.self) { eventType in
							Text(eventType.description)
						}
					} label: {
						Text("View event:")
					}
					
					
					Group {
						switch selection.event {
						case .equinox:
							Picker(selection: $selection.equinoxMonth) {
								ForEach(Selection.EquinoxMonth.allCases, id: \.self) { eventType in
									Text(eventType.description)
								}
							} label: {
								Text("At month:")
									.id("monthSelector")
							}
						case .solstice:
							Picker(selection: $selection.solsticeMonth) {
								ForEach(Selection.SolsticeMonth.allCases, id: \.self) { eventType in
									Text(eventType.description)
								}
							} label: {
								Text("At month:")
									.id("monthSelector")
							}
						}
					}

					
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
					Text("Imagery Source: [NASA Visible Earth Catalog](https://visibleearth.nasa.gov/collection/1484/blue-marble)")
				}
			}
			.formStyle(.grouped)
			.navigationTitle("Equinox and Solstice")
			.task(id: selection) {
				let action = SCNAction.rotateTo(
					x: 0,
					y: selection.sunAngle,
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
}

struct InformationSheetView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			EquinoxAndSolsticeInfoView()
		}
	}
}

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
