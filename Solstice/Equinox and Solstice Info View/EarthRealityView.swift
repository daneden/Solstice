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

	#if !os(visionOS)
		@State private var yawController = CameraYawController()
	#endif

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
					// A narrow field of view (vs. the 60° default) acts like a longer lens,
					// flattening the globe's apparent curvature; the camera sits further back
					// to keep it framed at the same size.
					let camera = Entity()
					camera.components.set(PerspectiveCameraComponent(fieldOfViewInDegrees: 30))
					camera.look(at: .zero, from: [0, 0, 0.5], relativeTo: nil)
					yawController.rig.addChild(camera)
					content.add(yawController.rig)
					yawController.attach(to: content)

					// visionOS lights the globe with the wearer's environment IBL; the non-AR
					// virtual scene has none, so the globe reads dark. ImageBasedLightComponent
					// is inert in this scene (intensityExponent had no effect at any value), so
					// approximate even lighting with directional lights, which do work here:
					// a headlight plus four side lights overlap into near-flat coverage of the
					// visible hemisphere. The cluster is parented to the camera, so the small
					// residual variation is locked to the screen and never sweeps across the
					// geography while the globe spins. A light shines along its -Z axis; the
					// tilts swing that axis toward each edge of the view.
					let lightTilts: [(angle: Float, axis: SIMD3<Float>)] = [
						(0, [0, 1, 0]),          // headlight, straight down the view axis
						(.pi / 2, [0, 1, 0]),    // lights the right limb
						(-.pi / 2, [0, 1, 0]),   // lights the left limb
						(.pi / 2, [1, 0, 0]),    // lights the bottom limb
						(-.pi / 2, [1, 0, 0]),   // lights the top limb
					]
					for tilt in lightTilts {
						let light = Entity()
						light.components.set(DirectionalLightComponent(color: .white, intensity: 6000))
						light.orientation = simd_quatf(angle: tilt.angle, axis: tilt.axis)
						camera.addChild(light)
					}
				#endif
			} placeholder: {
				ProgressView()
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			#if !os(visionOS)
			// The built-in orbit control also tilts vertically and zooms; the globe only
			// needs a horizontal spin, so a plain horizontal drag yaws the camera rig
			// instead. Dragging right spins the globe right (content follows the finger).
			.gesture(
				DragGesture()
					.onChanged { value in
						yawController.drag(byPoints: Float(value.translation.width))
					}
					.onEnded { value in
						yawController.endDrag(
							atPoints: Float(value.translation.width),
							pointsPerSecond: Float(value.velocity.width)
						)
					}
			)
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
		.background(alignment: .topTrailing) {
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

#if !os(visionOS)
	/// Spins the camera rig from the horizontal drag and carries flick momentum after
	/// the finger lifts. SwiftUI has no per-frame hook for a free-spinning entity, so —
	/// like `TerminatorAnimator` — the momentum integrates on the render loop via a
	/// `SceneEvents.Update` subscription, decaying exponentially like a scroll view.
	@MainActor
	private final class CameraYawController {
		/// Parent of the camera. Yawing this around the world Y axis orbits the camera
		/// horizontally while it keeps looking at the globe.
		let rig = Entity()

		/// Maps drag distance to yaw: ~0.5° per point spins the globe half a turn
		/// across a typical view width.
		private let radiansPerPoint: Float = 0.009

		/// Fraction of angular velocity shed per second. 2 matches the feel of
		/// `UIScrollView`'s normal deceleration rate (0.998 per millisecond).
		private let decayPerSecond: Float = 2

		/// Below this speed (radians per second) the spin is imperceptible; stop it
		/// so the render-loop step returns to its idle early-out.
		private let restSpeed: Float = 0.02

		private var committedYaw: Float = 0
		private var yaw: Float = 0
		private var angularVelocity: Float = 0
		private var subscription: EventSubscription?

		func attach(to content: some RealityViewContentProtocol) {
			subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
				self?.step(deltaTime: Float(event.deltaTime))
			}
		}

		/// The drag is negated so content follows the finger: dragging right moves the
		/// camera left around the globe, which reads as the globe spinning right.
		func drag(byPoints points: Float) {
			angularVelocity = 0
			setYaw(committedYaw - points * radiansPerPoint)
		}

		func endDrag(atPoints points: Float, pointsPerSecond: Float) {
			committedYaw -= points * radiansPerPoint
			setYaw(committedYaw)
			angularVelocity = -pointsPerSecond * radiansPerPoint
		}

		private func step(deltaTime: Float) {
			guard angularVelocity != 0 else { return }
			setYaw(yaw + angularVelocity * deltaTime)
			committedYaw = yaw
			angularVelocity *= exp(-decayPerSecond * deltaTime)
			if abs(angularVelocity) < restSpeed {
				angularVelocity = 0
			}
		}

		private func setYaw(_ newYaw: Float) {
			yaw = newYaw
			rig.orientation = simd_quatf(angle: newYaw, axis: [0, 1, 0])
		}
	}
#endif

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
