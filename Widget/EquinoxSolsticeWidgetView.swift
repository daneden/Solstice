//
//  OverviewWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 19/02/2023.
//

import SwiftUI
import WidgetKit
import SceneKit

#if os(iOS)
typealias NativeImage = UIImage
#elseif os(macOS)
typealias NativeImage = NSImage
#endif

extension Image {
	init(nativeImage: NativeImage) {
#if os(iOS)
		self.init(uiImage: nativeImage)
#elseif os(macOS)
		self.init(nsImage: nativeImage)
#endif
	}
}

struct EquinoxSolsticeWidgetView: View {
	@Environment(\.widgetRenderingMode) private var renderingMode
	@Environment(\.widgetFamily) private var family
	@Environment(\.sizeCategory) private var sizeCategory
	
	var entry: SolsticeWidgetTimelineEntry
	
	var location: SolsticeWidgetLocation {
		entry.location
	}
	
	@State var scene: EarthScene? = EarthScene()
	
	var body: some View {
		GeometryReader { geo in
			ZStack {
				if let image = renderImage(size: geo.size) {
					Canvas { context, size in
						context.addFilter(.blur(radius: 0.15))
						for _ in 0..<100 {
							let x = Double.random(in: 0..<size.width)
							let y = Double.random(in: 0..<size.height)
							let size = Double.random(in: 0.2..<2)
							let opacity = Double.random(in: 0.3..<1)
							context.opacity = opacity
							context.blendMode = .plusLighter
							context.draw(Image(systemName: "circle.fill"), in: CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: size, height: size)))
						}
					}
					
					Image(nativeImage: image)
						.resizable()
						.aspectRatio(contentMode: .fit)
				}
				
				VStack {
					Spacer()
					HStack {
						nextEventName
							.fontWeight(.bold)
						
						Spacer()
						
						Text(nextEvent, format: .relative(presentation: .named))
						Text(nextEvent, style: .date)
							.foregroundStyle(.secondary)
					}
					.font(.footnote)
					.padding()
					.shadow(radius: 6)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
		.background()
		.preferredColorScheme(.dark)
	}
	
	func renderImage(size: CGSize) -> NativeImage? {
		let scene = EarthScene(earthNode: EarthNode.naturalNoAnimation)
		let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice())
		renderer.scene = scene
		renderer.autoenablesDefaultLighting = true
		
		let cameraContainer = SCNNode()
		let cameraNode = SCNNode()
		cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
		let camera = SCNCamera()
		cameraNode.camera = camera
		camera.focalLength = 50
		cameraContainer.addChildNode(cameraNode)
		scene.rootNode.addChildNode(cameraContainer)
		
		let lat = SKFloat(Angle(degrees: entry.location.latitude).radians)
		let long = SKFloat(Angle(degrees: entry.location.longitude).radians)
		let earthRotation = scene.earthRotationAmount(for: entry.date)
		
		cameraContainer.eulerAngles = SCNVector3(x: -lat, y: long + earthRotation.y + .pi / 2, z: SKFloat(Angle(degrees: 23).radians))
		
		renderer.pointOfView = cameraNode
		renderer.pointOfView?.constraints?.append(SCNLookAtConstraint(target: scene.earthNode))
		
		scene.simulateDate(entry.date)
		SCNTransaction.flush()
		return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .none)
	}
	
	var nextSolstice: Date {
		Date().nextSolstice.startOfDay
	}
	
	var nextEquinox: Date {
		Date().nextEquinox.startOfDay
	}
	
	var nextEvent: Date {
		nextEquinox < nextSolstice ? nextEquinox : nextSolstice
	}
	
	var nextEventName: Text {
		Text("\(nextEventMonthName) \(nextEquinox < nextSolstice ? "Equinox" : "Solstice")")
	}
	
	var nextEventMonthName: String {
		nextEvent.formatted(.dateTime.month(.wide))
	}
}

struct EquinoxSolsticeWidgetView_Previews: PreviewProvider {
	static var previews: some View {
		EquinoxSolsticeWidgetView(entry: SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
			.previewContext(WidgetPreviewContext(family: .systemLarge))
	}
}
