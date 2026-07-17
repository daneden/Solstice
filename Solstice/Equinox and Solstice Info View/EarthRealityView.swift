//
//  EarthRealityView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/06/2024.
//

import RealityKit
import RealityKitContent
import SwiftUI

/// The single, cross-platform globe used to illustrate how the sun's coverage of
/// Earth shifts across the seasons. RealityKit gives visionOS true volumetric depth
/// and lets iOS/macOS share the same scene and shader-driven day/night terminator.
struct EarthRealityView: View {

	@State private var selection: AnnualSolarEvent
	@State private var terminator: TerminatorAnimator

	init(selection: AnnualSolarEvent = .juneSolstice) {
		_selection = State(initialValue: selection)
		_terminator = State(initialValue: TerminatorAnimator(angleDegrees: Float(selection.terminatorAngleDegrees)))
	}

	var body: some View {
		VStack(spacing: 16) {
			RealityView { content in
				if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle),
				   let earth = scene.findEntity(named: "Earth")
				{
					content.add(scene)
					terminator.attach(to: earth, content: content)
				}

				#if !os(visionOS)
					// visionOS is the camera (the wearer); other platforms need one to frame
					// the ~0.1m globe in the non-AR virtual scene.
					let camera = Entity()
					camera.components.set(PerspectiveCameraComponent())
					camera.look(at: .zero, from: [0, 0, 0.25], relativeTo: nil)
					content.add(camera)
				#endif
			}
			#if !os(visionOS)
			.realityViewCameraControls(.orbit)
			#endif
			.aspectRatio(1, contentMode: .fit)
			.frame(maxWidth: .infinity)

			Picker(selection: $selection) {
				ForEach(AnnualSolarEvent.allCases, id: \.self) { event in
					Text(event.shortMonthDescription)
				}
			} label: {
				Text("Month:")
			}
			.pickerStyle(.segmented)
		}
		.overlay(alignment: .topTrailing) {
			SolarSystemMiniMap(event: selection, rotation: .degrees(Double(terminator.currentAngle)))
		}
		.onChange(of: selection) { _, newValue in
			terminator.retarget(toDegrees: Float(newValue.terminatorAngleDegrees))
		}
	}
}

/// Eases the shader graph's `Angle` parameter (the day/night terminator) toward a
/// target on every rendered frame via a `SceneEvents.Update` subscription. Shader-graph
/// parameters aren't animatable by RealityKit or interpolable through SwiftUI's view
/// system, so we drive them from the render loop; SwiftUI only sets the target when the
/// selected month changes. `currentAngle` is observed so the mini-map sweeps in lockstep.
@Observable
@MainActor
private final class TerminatorAnimator {
	/// The currently-rendered angle, in degrees. Observed so SwiftUI views can follow it.
	var currentAngle: Float

	/// Higher eases faster. ~8 settles in ~0.6s, matching the old SceneKit transition.
	@ObservationIgnored private let responsiveness: Float = 8

	@ObservationIgnored private var targetAngle: Float
	@ObservationIgnored private weak var earth: Entity?
	@ObservationIgnored private var subscription: EventSubscription?

	init(angleDegrees: Float) {
		currentAngle = angleDegrees
		targetAngle = angleDegrees
	}

	func attach(to earth: Entity, content: some RealityViewContentProtocol) {
		self.earth = earth
		apply()
		subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
			self?.step(deltaTime: Float(event.deltaTime))
		}
	}

	/// Move the target along the shortest arc so Dec↔March never sweeps the long way,
	/// the way SceneKit's `usesShortestUnitArc` did. `targetAngle` accumulates, so
	/// `currentAngle` chases a continuous value rather than snapping across the ±180° seam.
	func retarget(toDegrees raw: Float) {
		var delta = (raw - targetAngle).truncatingRemainder(dividingBy: 360)
		if delta > 180 { delta -= 360 }
		if delta < -180 { delta += 360 }
		targetAngle += delta
	}

	private func step(deltaTime: Float) {
		let remaining = targetAngle - currentAngle
		guard abs(remaining) > 0.01 else {
			if currentAngle != targetAngle { currentAngle = targetAngle; apply() }
			return
		}
		currentAngle += remaining * min(1, deltaTime * responsiveness)
		apply()
	}

	private func apply() {
		guard let earth,
		      var model = earth.components[ModelComponent.self],
		      var material = model.materials.first as? ShaderGraphMaterial
		else {
			return
		}
		try? material.setParameter(name: "Angle", value: .float(currentAngle))
		model.materials = [material]
		earth.components.set(model)
	}
}

private extension AnnualSolarEvent {
	/// The `Angle` shader-graph parameter, in degrees. Matches the sign convention the
	/// scene's `dayNightAlphaMix` graph expects.
	var terminatorAngleDegrees: Double {
		Angle(radians: sunAngle).degrees * -1
	}
}

#Preview {
	EarthRealityView()
}
