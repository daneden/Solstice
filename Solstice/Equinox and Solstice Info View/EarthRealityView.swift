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
	@State private var sceneIsReady = false

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
					withAnimation(.easeIn(duration: 0.6)) {
						sceneIsReady = true
					}
				}

				#if !os(visionOS)
					// visionOS is the camera (the wearer); other platforms need one to frame
					// the ~0.1m globe in the non-AR virtual scene.
					let camera = Entity()
					camera.components.set(PerspectiveCameraComponent())
					camera.look(at: .zero, from: [0, 0, 0.25], relativeTo: nil)
					content.add(camera)

					// visionOS lights the globe with the system's environment IBL; the non-AR
					// virtual scene has none, so the globe reads dark. Parent a gentle key light
					// to the camera so it acts as a headlight — it always lifts the face the
					// viewer is looking at, following the orbit control. Tune `intensity` to taste.
					let keyLight = Entity()
					keyLight.components.set(DirectionalLightComponent(color: .white, intensity: 12000))
					camera.addChild(keyLight)
				#endif
			} placeholder: {
				ProgressView()
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			#if !os(visionOS)
			.realityViewCameraControls(.orbit)
			#endif
			.aspectRatio(1, contentMode: .fit)
			.frame(maxWidth: .infinity)
			#if !os(visionOS)
				.background {
					// The glow only makes sense framing the globe, so fade it in once the
					// scene has actually loaded rather than haloing the loading indicator.
					AtmosphereGlow()
						.opacity(sceneIsReady ? 1 : 0)
				}
			#endif

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
			// Isolate the per-frame `currentAngle` read to this child so the enclosing
			// body — and the Picker in it — isn't rebuilt every frame during the sweep
			// (which would swallow taps until the animation settled).
			AnimatedMiniMap(event: selection, terminator: terminator)
		}
		.onChange(of: selection) { _, newValue in
			terminator.retarget(toDegrees: Float(newValue.terminatorAngleDegrees))
		}
	}
}

/// A soft blue halo drawn behind the globe. The sphere's silhouette is always a centered
/// circle regardless of orbit, so a radial gradient sitting just past the globe's rim reads
/// as an atmosphere. Rendered behind the (transparent-backed) RealityView. Tune the color,
/// radii, and opacity to taste.
private struct AtmosphereGlow: View {
	var body: some View {
		GeometryReader { proxy in
			let side = min(proxy.size.width, proxy.size.height)
			RadialGradient(
				colors: [
					Color(red: 0.36, green: 0.64, blue: 1.0).opacity(0.25),
					Color(red: 0.36, green: 0.64, blue: 1.0).opacity(0),
				],
				center: .center,
				startRadius: side * 0.34,
				endRadius: side * 0.5
			)
			.blur(radius: side * 0.02)
		}
	}
}

/// Renders the mini-map from the animator's live angle. Kept as its own view so the
/// frame-by-frame `currentAngle` updates only invalidate this small overlay, leaving the
/// month Picker responsive to taps mid-animation.
private struct AnimatedMiniMap: View {
	let event: AnnualSolarEvent
	let terminator: TerminatorAnimator

	var body: some View {
		SolarSystemMiniMap(event: event, rotation: .degrees(Double(terminator.currentAngle)))
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
