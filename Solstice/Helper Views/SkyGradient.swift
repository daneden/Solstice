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
	var rayleigh = SIMD3<Double>(5.8e-6, 13.5e-6, 33.1e-6)
	/// Mie scattering coefficient (1/m).
	var mie = 21e-6
	/// Henyey–Greenstein asymmetry: how tightly the Mie glow hugs the sun (0…1).
	var mieG = 0.76
	/// Ozone absorption per RGB wavelength (1/m) — deepens twilight blues and purples.
	var ozone = SIMD3<Double>(0.650e-6, 1.881e-6, 0.085e-6)

	var rayleighScaleHeight = 8000.0
	var mieScaleHeight = 1200.0
	var planetRadius = 6.36e6
	var atmosphereRadius = 6.42e6

	var sunIntensity = 22.0
	/// Multiplier applied before tone-mapping. The main lever for overall brightness.
	var exposure = 3.0

	var viewSamples = 16
	var lightSamples = 8

	/// Mesh dimensions. More columns tighten the sun glow; more rows sharpen the horizon band.
	var meshWidth = 7
	var meshHeight = 5
	/// Highest view elevation sampled (top of the rendered strip), in degrees.
	var maxElevationDeg = 60.0
	/// Horizontal degrees of azimuth spanned across the full width of the gradient.
	var azimuthSpanDeg = 180.0

	static let standard = SkyModel()

	// MARK: Radiance

	/// Linear (pre-tone-map) RGB radiance for a view direction, given the sun's altitude.
	/// - Parameters:
	///   - sunAltitudeDeg: Sun altitude above the horizon, in degrees (negative below).
	///   - viewElevationDeg: View elevation above the horizon, in degrees.
	///   - relativeAzimuthDeg: View azimuth relative to the sun, in degrees (0 = toward the sun).
	func radiance(sunAltitudeDeg: Double, viewElevationDeg: Double, relativeAzimuthDeg: Double) -> SIMD3<Double> {
		let sa = sunAltitudeDeg * .pi / 180
		let ve = viewElevationDeg * .pi / 180
		let raz = relativeAzimuthDeg * .pi / 180

		// Sun's horizontal azimuth is +x, up is +y.
		let sun = SIMD3<Double>(cos(sa), sin(sa), 0)
		let view = SIMD3<Double>(cos(ve) * cos(raz), sin(ve), cos(ve) * sin(raz))
		let origin = SIMD3<Double>(0, planetRadius, 0)

		guard let tMax = raySphereFar(origin, view, atmosphereRadius) else { return .zero }

		let cosTheta = simd_dot(view, sun)
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
		return (inRayleigh + inMie) * sunIntensity
	}

	/// Tone-mapped, gamma-encoded sky colour for a view direction.
	func color(sunAltitudeDeg: Double, viewElevationDeg: Double, relativeAzimuthDeg: Double) -> Color {
		tonemap(radiance(sunAltitudeDeg: sunAltitudeDeg,
		                 viewElevationDeg: viewElevationDeg,
		                 relativeAzimuthDeg: relativeAzimuthDeg))
	}

	// MARK: Mesh

	/// Builds the sky as a `MeshGradient`, plus the vertical colour ramp used by `SkyGradient.stops`.
	/// - Parameters:
	///   - sunAltitudeDeg: Sun altitude above the horizon, in degrees.
	///   - sunX: Sun's horizontal position as a fraction of the day (0…1), matching the daylight chart.
	func mesh(sunAltitudeDeg: Double, sunX: Double) -> (gradient: MeshGradient, stops: [Color]) {
		let w = meshWidth, h = meshHeight

		var points = [SIMD2<Float>]()
		var colors = [Color]()
		points.reserveCapacity(w * h)
		colors.reserveCapacity(w * h)

		for row in 0 ..< h {
			let rowY = Double(row) / Double(h - 1)
			let elevationFraction = 1 - rowY
			// Bias sampling toward the horizon, where colour varies most.
			let elevation = maxElevationDeg * elevationFraction * elevationFraction
			for col in 0 ..< w {
				let colX = Double(col) / Double(w - 1)
				let relativeAzimuth = (colX - sunX) * azimuthSpanDeg
				// Below the horizon the physical sky darkens to black — no artificial night floor.
				let vertexColor = color(sunAltitudeDeg: sunAltitudeDeg,
				                        viewElevationDeg: elevation,
				                        relativeAzimuthDeg: relativeAzimuth)
				points.append(SIMD2<Float>(Float(colX), Float(rowY)))
				colors.append(vertexColor)
			}
		}

		let gradient = MeshGradient(width: w, height: h, points: points, colors: colors,
		                            smoothsColors: true, colorSpace: .perceptual)

		// Vertical ramp of the column farthest from the sun (first = zenith, last = horizon).
		let farColumn = sunX < 0.5 ? w - 1 : 0
		let stops = (0 ..< h).map { colors[$0 * w + farColumn] }

		return (gradient, stops)
	}

	// MARK: Helpers

	/// Ozone concentration tent, peaking around 25 km.
	private func ozoneDensity(_ height: Double) -> Double {
		max(0, 1 - abs(height - 25000) / 15000)
	}

	/// Luminance-based Reinhard: compresses brightness while preserving chroma, so the daytime
	/// sky stays saturated blue instead of desaturating toward grey the way per-channel Reinhard does.
	private func tonemap(_ radiance: SIMD3<Double>) -> Color {
		let exposed = radiance * exposure
		let luminance = 0.2126 * exposed.x + 0.7152 * exposed.y + 0.0722 * exposed.z
		let scale = luminance > 0 ? 1 / (1 + luminance) : 0
		let mapped = exposed * scale
		return Color(.sRGB, red: encodeSRGB(mapped.x), green: encodeSRGB(mapped.y), blue: encodeSRGB(mapped.z))
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
	@Environment(\.timeZone) var timeZone

	var ntSolar: NTSolar? = nil

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
		let sunX: Double = {
			guard let solar else { return 0.5 }
			return min(max(date.timeIntervalSince(solar.startOfDay) / .twentyFourHours, 0), 1)
		}()
		return SkyModel.standard.mesh(sunAltitudeDeg: sunAltitude, sunX: sunX)
	}

	/// The vertical colour ramp; `first` is the sky/zenith, `last` the horizon.
	/// Consumed by `ShareSolarChartView` for the Instagram story background colours.
	var stops: [Color] {
		skyMesh.stops
	}

	var body: MeshGradient {
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
					SkyModel.standard.mesh(sunAltitudeDeg: altitude, sunX: 0.5).gradient
					Text("\(Int(altitude))°")
						.font(.headline.monospacedDigit())
						.foregroundStyle(.white)
						.shadow(radius: 2)
				}
			}
		}
	}
}

/// Interactive tuning surface for the model's sun altitude and horizontal position.
private struct SkyModelSliderPreview: View {
	@State private var altitude = 8.0
	@State private var sunX = 0.5

	var body: some View {
		VStack {
			SkyModel.standard.mesh(sunAltitudeDeg: altitude, sunX: sunX).gradient
				.ignoresSafeArea()
				.overlay(alignment: .bottom) {
					VStack(alignment: .leading) {
						Text("Altitude \(altitude, format: .number.precision(.fractionLength(1)))°")
						Slider(value: $altitude, in: -20 ... 90)
						Text("Sun X \(sunX, format: .number.precision(.fractionLength(2)))")
						Slider(value: $sunX, in: 0 ... 1)
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
