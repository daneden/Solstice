//
//  SkyGradient.swift
//  Solstice
//
//  Created by Daniel Eden on 21/02/2023.
//

import CoreLocation
import Foundation
import simd
import SwiftUI

// MARK: - SkyModel

/// A physically-motivated model of daytime sky colour.
///
/// Colours are derived from single-scattering atmospheric physics (Nishita-style):
/// a view ray is marched through a spherical-shell atmosphere, accumulating Rayleigh
/// (air) and Mie (aerosol) in-scattering with ozone absorption. The Mie forward lobe
/// produces the warm glow that anchors to the sun's position — the effect seen on the
/// Apple Watch solar faces — while Rayleigh gives the blue zenith and reddened horizon.
///
/// The output feeds a SwiftUI `MeshGradient`, so a single implementation works on every
/// surface (main app, widgets, watchOS) with no Metal. All constants are stored, so
/// tuning is a matter of changing `standard`'s values rather than the algorithm.
struct SkyModel {
	/// Rayleigh scattering coefficient per RGB wavelength (1/m).
	var rayleigh = SIMD3<Double>(3.8e-6, 11.5e-6, 38.1e-6)
	/// Mie scattering coefficient (1/m). Lower keeps the daytime sky bluer and the horizon cleaner
	/// (less neutral aerosol haze).
	var mie = 8e-6
	/// Henyey–Greenstein asymmetry: how tightly the Mie glow hugs the sun (0…1).
	var mieG = 0.8
	/// Ozone absorption per RGB wavelength (1/m) — deepens twilight blues and purples.
	var ozone = SIMD3<Double>(0.650e-6, 1.881e-6, 0.085e-6)
	/// Single scattering alone leaves long near-horizon paths yellow-green under a high sun: blue is
	/// scattered out of the ray faster than in, and with no second bounce nothing replaces it. This
	/// approximates multiple scattering with an isotropic, sky-tinted fill wherever the view path is
	/// optically thick, fading with sun altitude so twilight and night keep their single-scatter
	/// colours. Higher = paler, bluer horizon at midday.
	var multipleScattering = 0.02

	var rayleighScaleHeight = 8000.0
	var mieScaleHeight = 1200.0
	var planetRadius = 6.36e6
	var atmosphereRadius = 6.42e6

	var sunIntensity = 22.0
	/// Multiplier applied before tone-mapping. The main lever for overall brightness.
	var exposure = 3.0
	/// Faint skylight floor added before tone-mapping so night settles into a deep navy rather than
	/// pure black, and the day→night ramp stays smooth instead of popping to black.
	var ambientRadiance = SIMD3<Double>(0.0015, 0.003, 0.008)

	var viewSamples = 16
	var lightSamples = 8

	/// Mesh dimensions. A denser grid renders the 2-D sun glow more smoothly.
	var meshWidth = 9
	var meshHeight = 7
	/// View elevations sampled at the bottom and top of the rendered strip, in degrees. Keeping the
	/// bottom above the horizon avoids the muddy long-path haze and gives a calmer, more even ramp.
	var minElevationDeg = 6.0
	var maxElevationDeg = 45.0
	/// Degrees of scattering angle per unit of normalised distance from the sun anchor.
	/// Higher values shrink the glow; lower values spread it across the gradient.
	var glowAngularScaleDeg = 120.0

	/// Below a horizon there is no sky to march — only ground. The ground band renders as the sky
	/// just above the horizon reflected darkly, so twilight's warm band carries into it. This is the
	/// fraction of that light reflected right at the horizon (in display-linear space, after
	/// tone-mapping); it fades further with depth.
	var groundReflectance = 0.12
	/// Extra scattering angle added to ground vertices, pushing the reflected glow out of the tight
	/// forward-Mie lobe: the ground keeps a hint of warmth under the sun instead of mirroring the
	/// full aureole below the horizon.
	var groundGlowAngularOffsetDeg = 30.0
	/// View elevation sampled for the ground's illumination.
	var groundSourceElevationDeg = 2.5

	/// Sun-relative azimuth assumed on ambient surfaces (no `sunAnchor`): far enough from the sun
	/// that no bright spot forms anywhere, close enough that sunsets still warm the sky.
	var ambientSunDeltaAzimuthDeg = 60.0

	/// The dial ring (circular chart) samples the sky at this view elevation…
	var dialViewElevationDeg = 12.0
	/// …looking this far from the sun (as a cosine, ~60°). Only the night and twilight arcs of the
	/// ring stay visible beneath the dynamic day wedge, so this is deliberately wide: the twilight
	/// arcs keep their transmittance-driven colour without showing the sun's aureole itself.
	var dialScatterCosTheta = 0.5

	static let standard = SkyModel()

	// MARK: Radiance

	/// Linear (pre-tone-map) RGB radiance for a view direction, given the sun's altitude.
	///
	/// The atmosphere is spherically symmetric, so the ray-march path lengths depend only on the
	/// view elevation and the sun altitude — the view's azimuth only ever entered through the phase
	/// functions. Supplying `scatterCosTheta` directly lets the mesh place the glow anywhere (e.g. at
	/// a chart's sun marker) without pretending the sky is a literal dome.
	/// - Parameters:
	///   - sunAltitudeDeg: Sun altitude above the horizon, in degrees (negative below).
	///   - viewElevationDeg: View elevation above the horizon, in degrees.
	///   - scatterCosTheta: Cosine of the angle between the view ray and the sun (1 = straight at it).
	func radiance(sunAltitudeDeg: Double, viewElevationDeg: Double, scatterCosTheta: Double) -> SIMD3<Double> {
		let sa = sunAltitudeDeg * .pi / 180
		let ve = viewElevationDeg * .pi / 180

		// Up is +y; both rays live in the x-y plane since only their path lengths matter here.
		let sun = SIMD3<Double>(cos(sa), sin(sa), 0)
		let view = SIMD3<Double>(cos(ve), sin(ve), 0)
		let origin = SIMD3<Double>(0, planetRadius, 0)

		guard let tMax = raySphereFar(origin, view, atmosphereRadius) else { return .zero }

		let cosTheta = min(max(scatterCosTheta, -1), 1)
		let phaseR = 3.0 / (16.0 * .pi) * (1 + cosTheta * cosTheta)
		let g = mieG
		let hgDenom = pow(max(1e-4, 1 + g * g - 2 * g * cosTheta), 1.5)
		let phaseM = (1 - g * g) / (4 * .pi * hgDenom)

		let mieExt = mie * 1.11 // aerosols absorb a little as well as scatter

		let seg = tMax / Double(viewSamples)
		var sumR = SIMD3<Double>.zero
		var sumM = SIMD3<Double>.zero
		var odR = 0.0, odM = 0.0, odO = 0.0 // optical depth accumulated along the view ray

		for i in 0 ..< viewSamples {
			let t = (Double(i) + 0.5) * seg
			let p = origin + view * t
			let h = max(0, simd_length(p) - planetRadius)

			let dR = exp(-h / rayleighScaleHeight) * seg
			let dM = exp(-h / mieScaleHeight) * seg
			let dO = ozoneDensity(h) * seg
			odR += dR; odM += dM; odO += dO

			// Skip samples the sun can't reach (below the local horizon = in planet shadow).
			guard !hitsPlanet(p, sun), let tLight = raySphereFar(p, sun, atmosphereRadius) else { continue }

			let lSeg = tLight / Double(lightSamples)
			var lodR = 0.0, lodM = 0.0, lodO = 0.0
			for j in 0 ..< lightSamples {
				let pl = p + sun * ((Double(j) + 0.5) * lSeg)
				let hl = max(0, simd_length(pl) - planetRadius)
				lodR += exp(-hl / rayleighScaleHeight) * lSeg
				lodM += exp(-hl / mieScaleHeight) * lSeg
				lodO += ozoneDensity(hl) * lSeg
			}

			let tau = rayleigh * (odR + lodR)
				+ SIMD3<Double>(repeating: mieExt * (odM + lodM))
				+ ozone * (odO + lodO)
			let transmittance = SIMD3<Double>(exp(-tau.x), exp(-tau.y), exp(-tau.z))

			sumR += transmittance * dR
			sumM += transmittance * dM
		}

		let inRayleigh = rayleigh * sumR * phaseR
		let inMie = sumM * (mie * phaseM)

		// Multiple-scattering fill: strongest where the view path has extinguished the single-
		// scattered light (1 - transmittance), tinted like the scattering medium itself so it
		// reads as pale blue rather than the yellow-green the extinguished path leaves behind.
		let tauView = rayleigh * odR + SIMD3<Double>(repeating: mieExt * odM) + ozone * odO
		let pathOpacity = SIMD3<Double>(1 - exp(-tauView.x), 1 - exp(-tauView.y), 1 - exp(-tauView.z))
		let skyTint = rayleigh / simd_reduce_max(rayleigh)
		let inMultiple = multipleScattering * max(0, sin(sa)) * pathOpacity * skyTint

		return (inRayleigh + inMie + inMultiple) * sunIntensity
	}

	/// Tone-mapped, gamma-encoded sky colour for a view direction, including the ambient skylight floor.
	func color(sunAltitudeDeg: Double, viewElevationDeg: Double, scatterCosTheta: Double) -> Color {
		let scattered = radiance(sunAltitudeDeg: sunAltitudeDeg,
		                         viewElevationDeg: viewElevationDeg,
		                         scatterCosTheta: scatterCosTheta)
		return tonemap(scattered + ambientRadiance)
	}

	// MARK: Mesh

	/// Builds the sky as a `MeshGradient`, plus the vertical colour ramp used by `SkyGradient.stops`.
	///
	/// The warm sun glow is centred on `sunAnchor` so it can be aligned with the sun marker each chart
	/// draws. A vertex's scattering angle grows with its normalised distance from the anchor, so the
	/// forward-Mie glow peaks exactly at the anchor and falls off around it.
	/// - Parameters:
	///   - sunAltitudeDeg: Sun altitude above the horizon, in degrees.
	///   - sunAnchor: The sun's position in the gradient's own bounds (0…1, y-down), or `nil` for
	///     ambient surfaces, which render elevation-driven colour with no anchored glow.
	///   - horizonFraction: The horizon line's vertical position in the gradient's bounds (0…1,
	///     y-down). When set, rows below it render as ground instead of sky, with a row placed
	///     tight under the line so the horizon reads as a crisp edge across the full width.
	func mesh(sunAltitudeDeg: Double, sunAnchor: UnitPoint?, horizonFraction: Double? = nil) -> (gradient: MeshGradient, stops: [Color]) {
		let rows = rowLayout(horizonFraction: horizonFraction)
		let w = meshWidth, h = rows.count

		var points = [SIMD2<Float>]()
		var colors = [Color]()
		points.reserveCapacity(w * h)
		colors.reserveCapacity(w * h)

		for (rowY, content) in rows {
			let elevationDeg: Double = switch content {
			case let .sky(elevationDeg): elevationDeg
			case .ground: groundSourceElevationDeg
			}
			// Ground vertices widen their scattering angle so the reflected glow falls outside the
			// tight forward-Mie lobe — only a hint of the aureole survives below the horizon.
			let groundOffset: Double = switch content {
			case .sky: 0
			case .ground: groundGlowAngularOffsetDeg * .pi / 180
			}
			for col in 0 ..< w {
				let colX = Double(col) / Double(w - 1)
				let scatterCosTheta: Double = if let sunAnchor {
					cos(min(.pi, hypot(colX - Double(sunAnchor.x), rowY - Double(sunAnchor.y)) * glowAngularScaleDeg * .pi / 180 + groundOffset))
				} else {
					ambientScatterCosTheta(sunAltitudeDeg: sunAltitudeDeg, viewElevationDeg: elevationDeg)
				}
				let vertexColor: Color = switch content {
				case .sky:
					color(sunAltitudeDeg: sunAltitudeDeg,
					      viewElevationDeg: elevationDeg,
					      scatterCosTheta: scatterCosTheta)
				case let .ground(reflectance):
					groundColor(sunAltitudeDeg: sunAltitudeDeg,
					            scatterCosTheta: scatterCosTheta,
					            reflectance: reflectance)
				}
				points.append(SIMD2<Float>(Float(colX), Float(rowY)))
				colors.append(vertexColor)
			}
		}

		let gradient = MeshGradient(width: w, height: h, points: points, colors: colors,
		                            smoothsColors: true, colorSpace: .perceptual)

		// Vertical ramp of the column farthest from the sun (first = zenith, last = horizon/ground).
		let farColumn: Int = (sunAnchor?.x ?? 1) < 0.5 ? w - 1 : 0
		let stops: [Color] = (0 ..< h).map { row in colors[row * w + farColumn] }

		return (gradient, stops)
	}

	private enum RowContent {
		case sky(elevationDeg: Double)
		case ground(reflectance: Double)
	}

	/// Vertical mesh layout: each row's y position and what it samples. Without a horizon the strip
	/// is all sky; with one, the sky compresses above it and the remainder renders as ground.
	private func rowLayout(horizonFraction: Double?) -> [(y: Double, content: RowContent)] {
		// A horizon at (or beyond) the bottom edge leaves no room for a ground band — all sky.
		guard let horizonFraction, horizonFraction < 0.92 else {
			return (0 ..< meshHeight).map { row in
				let y = Double(row) / Double(meshHeight - 1)
				return (y, .sky(elevationDeg: minElevationDeg + (maxElevationDeg - minElevationDeg) * (1 - y)))
			}
		}

		let hf = max(horizonFraction, 0.08)
		let skyRows = meshHeight - 2
		var rows: [(y: Double, content: RowContent)] = (0 ..< skyRows).map { row in
			let fraction = Double(row) / Double(skyRows - 1)
			return (y: hf * fraction,
			        content: .sky(elevationDeg: maxElevationDeg + (minElevationDeg - maxElevationDeg) * fraction))
		}
		// The first ground row sits almost on top of the last sky row, so the sky→ground transition
		// spans a fraction of a point and the horizon reads as a crisp edge exactly on the chart's
		// horizon line; the bottom row fades the ground out.
		rows.append((y: hf + 0.004, content: .ground(reflectance: groundReflectance)))
		rows.append((y: 1, content: .ground(reflectance: groundReflectance * 0.4)))
		return rows
	}

	/// Scattering cosine for ambient surfaces: the true angular distance to a sun offset by a fixed
	/// azimuth, so colour varies with elevation only and the glow never anchors to a point.
	private func ambientScatterCosTheta(sunAltitudeDeg: Double, viewElevationDeg: Double) -> Double {
		let sa = sunAltitudeDeg * .pi / 180
		let ve = viewElevationDeg * .pi / 180
		let deltaAzimuth = ambientSunDeltaAzimuthDeg * .pi / 180
		return sin(ve) * sin(sa) + cos(ve) * cos(sa) * cos(deltaAzimuth)
	}

	/// Ground: the sky just above the horizon, reflected darkly. The reflection happens in
	/// display-linear space — scene-linear reflectance would be mostly undone by the
	/// luminance-compressing tone-map, leaving the daytime ground too bright. Twilight's warm band
	/// still carries into it, and the ambient floor keeps the ground no darker than the night sky,
	/// so chart content drawn over it stays legible.
	private func groundColor(sunAltitudeDeg: Double, scatterCosTheta: Double, reflectance: Double) -> Color {
		let sky = tonemapLinear(radiance(sunAltitudeDeg: sunAltitudeDeg,
		                                 viewElevationDeg: groundSourceElevationDeg,
		                                 scatterCosTheta: scatterCosTheta) + ambientRadiance)
		let nightFloor = ambientRadiance * exposure
		return encode(sky * reflectance + nightFloor)
	}

	// MARK: Dial

	/// Sky colours around a 24-hour dial, for circular charts: each angle is coloured by the sky at
	/// that time of day, so day, each twilight band, and night appear as arcs in their true positions.
	/// Stop locations are fractions of a day from midnight; align them using the chart's midnight angle.
	func dialStops(for solar: NTSolar, sampleCount: Int = 48) -> [Gradient.Stop] {
		// Coarser march than the mesh: the dial evaluates many directions, and colour varies smoothly
		// enough with altitude that the difference is invisible after tone-mapping.
		var coarse = self
		coarse.viewSamples = 8
		coarse.lightSamples = 4

		let start = solar.startOfDay
		var stops = (0 ..< sampleCount).map { i in
			let fraction = Double(i) / Double(sampleCount)
			let date = start.addingTimeInterval(fraction * .twentyFourHours)
			let color = coarse.color(sunAltitudeDeg: solar.altitude(at: date),
			                         viewElevationDeg: dialViewElevationDeg,
			                         scatterCosTheta: dialScatterCosTheta)
			return Gradient.Stop(color: color, location: fraction)
		}
		// Close the ring seamlessly.
		if let first = stops.first {
			stops.append(Gradient.Stop(color: first.color, location: 1))
		}
		return stops
	}

	// MARK: Helpers

	/// Ozone concentration tent, peaking around 25 km.
	private func ozoneDensity(_ height: Double) -> Double {
		max(0, 1 - abs(height - 25000) / 15000)
	}

	/// Luminance-based Reinhard: compresses brightness while preserving chroma, so the daytime
	/// sky stays saturated blue instead of desaturating toward grey the way per-channel Reinhard does.
	private func tonemapLinear(_ radiance: SIMD3<Double>) -> SIMD3<Double> {
		let exposed = radiance * exposure
		let luminance = 0.2126 * exposed.x + 0.7152 * exposed.y + 0.0722 * exposed.z
		let scale = luminance > 0 ? 1 / (1 + luminance) : 0
		return exposed * scale
	}

	private func tonemap(_ radiance: SIMD3<Double>) -> Color {
		encode(tonemapLinear(radiance))
	}

	private func encode(_ mapped: SIMD3<Double>) -> Color {
		Color(.sRGB, red: encodeSRGB(mapped.x), green: encodeSRGB(mapped.y), blue: encodeSRGB(mapped.z))
	}

	private func encodeSRGB(_ value: Double) -> Double {
		let c = min(max(value, 0), 1)
		return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
	}

	/// Far intersection distance of a ray with a sphere centred at the origin, if any.
	private func raySphereFar(_ origin: SIMD3<Double>, _ direction: SIMD3<Double>, _ radius: Double) -> Double? {
		let b = 2 * simd_dot(origin, direction)
		let c = simd_dot(origin, origin) - radius * radius
		let discriminant = b * b - 4 * c
		guard discriminant >= 0 else { return nil }
		let t = (-b + sqrt(discriminant)) / 2
		return t > 0 ? t : nil
	}

	/// Whether a ray from `origin` toward `direction` enters the planet (i.e. is shadowed).
	private func hitsPlanet(_ origin: SIMD3<Double>, _ direction: SIMD3<Double>) -> Bool {
		let b = 2 * simd_dot(origin, direction)
		let c = simd_dot(origin, origin) - planetRadius * planetRadius
		let discriminant = b * b - 4 * c
		guard discriminant >= 0 else { return false }
		let tNear = (-b - sqrt(discriminant)) / 2
		return tNear > 0
	}
}

// MARK: - SkyGradient

struct SkyGradient: View, ShapeStyle {
	/// Named coordinate space shared between a chart and its `SkyGradient` background so the sun
	/// marker's geometry can be reported via `SkyChartGeometryPreferenceKey` and normalised consistently.
	static let coordinateSpaceName = "skyGradient"

	@Environment(\.timeZone) var timeZone

	var ntSolar: NTSolar? = nil

	/// Where the sun sits in this gradient's own bounds (0…1, y-down). Callers with chart geometry
	/// supply the sun marker's position; when `nil` (ambient surfaces like the watch container
	/// background or list rows) the sky has no anchored glow at all — only the altitude-driven ramp.
	var sunAnchor: UnitPoint? = nil

	/// The horizon line's vertical position in this gradient's own bounds (0…1, y-down). When set,
	/// the mesh renders ground below it; when `nil` (ambient surfaces like the watch container
	/// background or widgets) the gradient is all sky.
	var horizonFraction: Double? = nil

	private var effectiveSolar: NTSolar? {
		if let ntSolar {
			return ntSolar
		}
		return NTSolar(for: .now, coordinate: .proxiedToTimeZone, timeZone: timeZone)
	}

	private var skyMesh: (gradient: MeshGradient, stops: [Color]) {
		let solar = effectiveSolar
		let date = solar?.date ?? .now
		let sunAltitude = solar?.altitude(at: date) ?? 0
		return SkyModel.standard.mesh(sunAltitudeDeg: sunAltitude,
		                              sunAnchor: sunAnchor,
		                              horizonFraction: horizonFraction)
	}

	/// The vertical colour ramp; `first` is the sky/zenith, `last` the horizon.
	/// Consumed by `ShareSolarChartView` for the Instagram story background colours.
	var stops: [Color] {
		skyMesh.stops
	}

	var body: some View {
		skyMesh.gradient
	}
}

// MARK: - Previews

private struct PreviewContainer: View {
	@Environment(\.timeZone) var timeZone
	@State var date = Date.now

	var solars: [NTSolar] {
		var result = [NTSolar?]()

		for i in stride(from: 0, to: 180, by: 15) {
			let location = CLLocationCoordinate2D(latitude: Double(i) - 90, longitude: 0)
			result.append(NTSolar(for: date, coordinate: location, timeZone: timeZone))
		}

		return result.compactMap { $0 }
	}

	var body: some View {
		TimelineView(.animation) { t in
			VStack(spacing: 0) {
				ForEach(solars, id: \.coordinate.latitude) { solar in
					ZStack {
						SkyGradient(ntSolar: solar)

						HStack {
							Text(solar.date, style: .time)
								.font(.largeTitle)

							Spacer()
							VStack {
								Text(solar.safeSunrise ... solar.safeSunset)
								Text(solar.daylightDuration.localizedString)
							}
						}
						.padding()
					}
				}
			}
			.monospacedDigit()
			.environment(\.colorScheme, .dark)
			.task(id: t.date) {
				date = date.addingTimeInterval(60)
			}
		}
	}
}

/// Sweeps the sun from below the horizon to overhead so the physical model can be eyeballed directly.
private struct AltitudeSweepPreview: View {
	let altitudes = stride(from: 80.0, through: -20.0, by: -12.5)

	var body: some View {
		VStack(spacing: 0) {
			ForEach(Array(altitudes), id: \.self) { altitude in
				ZStack {
					SkyModel.standard.mesh(sunAltitudeDeg: altitude, sunAnchor: .center, horizonFraction: 0.72).gradient
					Text(verbatim: "\(Int(altitude))°")
						.font(.headline.monospacedDigit())
						.foregroundStyle(.white)
						.shadow(radius: 2)
				}
			}
		}
	}
}

/// Interactive tuning surface for the model's sun altitude and the 2-D glow anchor.
private struct SkyModelSliderPreview: View {
	@State private var altitude = 8.0
	@State private var anchorX = 0.5
	@State private var anchorY = 0.5

	var body: some View {
		VStack {
			SkyModel.standard.mesh(sunAltitudeDeg: altitude, sunAnchor: UnitPoint(x: anchorX, y: anchorY)).gradient
				.ignoresSafeArea()
				.overlay(alignment: .bottom) {
					VStack(alignment: .leading) {
						Text(verbatim: "Altitude \(altitude.formatted(.number.precision(.fractionLength(1))))°")
						Slider(value: $altitude, in: -20 ... 90)
						Text(verbatim: "Anchor X \(anchorX.formatted(.number.precision(.fractionLength(2))))")
						Slider(value: $anchorX, in: 0 ... 1)
						Text(verbatim: "Anchor Y \(anchorY.formatted(.number.precision(.fractionLength(2))))")
						Slider(value: $anchorY, in: 0 ... 1)
					}
					.padding()
					.background(.thinMaterial, in: .rect(cornerRadius: 12))
					.padding()
					.foregroundStyle(.white)
				}
		}
	}
}

#Preview("Latitude sweep") {
	ScrollView {
		PreviewContainer()
	}
}

#Preview("Altitude sweep") {
	AltitudeSweepPreview()
		.ignoresSafeArea()
}

#Preview("Tuning") {
	SkyModelSliderPreview()
}
