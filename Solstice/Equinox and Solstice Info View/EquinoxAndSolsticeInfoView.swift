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

fileprivate enum Event: CaseIterable, Codable, Hashable {
	case marchEquinox, juneSolstice, septemberEquinox, decemberSolstice
	
	var description: LocalizedStringKey {
		switch self {
		case .marchEquinox:
			return "March Equinox"
		case .juneSolstice:
			return "June Solstice"
		case .septemberEquinox:
			return "September Equinox"
		case .decemberSolstice:
			return "December Solstice"
		}
	}
	
	var shortMonthDescription: LocalizedStringKey {
		switch self {
		case .marchEquinox:
			return "March"
		case .juneSolstice:
			return "June"
		case .septemberEquinox:
			return "September"
		case .decemberSolstice:
			return "December"
		}
	}
	
	var shortEventDescription: LocalizedStringKey {
		switch self {
		case .marchEquinox, .septemberEquinox:
			return "Equinox"
		case .juneSolstice, .decemberSolstice:
			return "Solstice"
		}
	}
	
	var sunAngle: CGFloat {
		switch self {
		case .marchEquinox:
			return -.pi / 2
		case .septemberEquinox:
			return .pi / 2
		case .juneSolstice:
			return 0
		case .decemberSolstice:
			return .pi
		}
	}
}

struct EquinoxAndSolsticeInfoView: View {
	@State private var selection: Event = .juneSolstice
	#if os(iOS)
	let resourceRequest = NSBundleResourceRequest(tags: ["earth"])
	#endif
	@State var scene: EarthScene?
	
	var body: some View {
		GeometryReader { geometry in
			Form {
				Section {
					ZStack(alignment: .topTrailing) {
						HStack {
							VStack(alignment: .trailing, spacing: 0) {
								Text(selection.shortMonthDescription)
									.fontWeight(.semibold)
								Text(selection.shortEventDescription)
							}
							.font(.subheadline)
							
							SolarSystemMinimap(angle: selection.sunAngle, size: 40)
								.foregroundStyle(Color.gray)
						}
						.padding()
						.foregroundStyle(.secondary)
						
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
					
					Picker(selection: $selection.animation()) {
						ForEach(Event.allCases, id: \.self) { eventType in
							Text(eventType.shortMonthDescription)
						}
					} label: {
						Text("Month of year")
					}
					.pickerStyle(.segmented)

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
			.onChange(of: selection) {
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
