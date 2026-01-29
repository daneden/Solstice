//
//  CircularSolarChart.swift
//  Solstice
//
//  Created by Daniel Eden on 04/10/2025.
//

import SwiftUI
import SunKit
import TimeMachine
import Suite
import enum Accelerate.vDSP

struct CircularSolarChart<Location: AnyLocation>: View {
	@AppStorage(Preferences.detailViewChartAppearance) private var appearance
	@Environment(\.colorScheme) private var colorScheme
	@Environment(\.timeMachine) private var timeMachine
	#if WIDGET_EXTENSION
	@Environment(\.widgetRenderingMode) private var widgetRenderingMode
	#endif

	@State private var size = CGSize.zero
	@State private var cachedSun: Sun?
	@State private var lastLocationKey: String?
	var date: Date?

	var location: Location

	var timeZone: TimeZone { location.timeZone }

	var sun: Sun? { cachedSun }

	private var locationKey: String {
		"\(location.coordinate.latitude),\(location.coordinate.longitude)"
	}
	
	var majorSunSize: Double {
		max(16, max(size.width, size.height) * 0.075)
	}
	
	var minorSunSize: Double {
		max(4, majorSunSize / 3)
	}
	
	var foregroundStyle: AnyShapeStyle {
		#if WIDGET_EXTENSION
		if widgetRenderingMode == .fullColor {
			switch appearance {
			case .graphical: return AnyShapeStyle(.white)
			case .simple: return AnyShapeStyle(.primary)
			}
		} else {
			return AnyShapeStyle(.primary)
		}
		#else
		switch appearance {
		case .graphical: return AnyShapeStyle(.white)
		case .simple: return AnyShapeStyle(.primary)
		}
		#endif
	}
	
	var blendMode: BlendMode {
		#if WIDGET_EXTENSION
		if widgetRenderingMode == .fullColor {
			switch appearance {
			case .graphical: return .plusLighter
			case .simple: return .normal
			}
		} else {
			return .normal
		}
		#else
		switch appearance {
		case .graphical: return .plusLighter
		case .simple: return .normal
		}
		#endif
	}
	
	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		
		return calendar
	}
	
	func angle(for date: Date) -> SwiftUI.Angle {
		Helpers.angle(for: date, timeZone: timeZone)
	}
	
	@ViewBuilder
	var background: some View {
		#if WIDGET_EXTENSION
		if widgetRenderingMode == .fullColor {
			if appearance == .graphical {
				sun?.view
			} else {
				Rectangle().fill(.regularMaterial)
			}
		} else {
			Rectangle().fill(.primary.quinary)
		}
		#else
		if appearance == .graphical {
			sun?.view
		} else {
			Rectangle().fill(.regularMaterial)
		}
		#endif
	}
	
	var aboveHorizonSun: some View {
		Circle()
			.fill(foregroundStyle)
			.frame(width: majorSunSize)
			.frame(maxWidth: .infinity, alignment: .trailing)
			.padding(.trailing, minorSunSize / 2)
			.rotationEffect(angle(for: sun?.date ?? .now))
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	var belowHorizonSun: some View {
		background.mask {
			Circle()
		}
		.overlay {
			Circle()
				.fill(.clear)
				.strokeBorder(foregroundStyle, lineWidth: 3)
		}
				.frame(width: majorSunSize)
				.frame(maxWidth: .infinity, alignment: .trailing)
				.padding(.trailing, minorSunSize / 2)
				.rotationEffect(angle(for: sun?.date ?? .now))
				.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	var safeSunriseSunsetShape: some Shape {
		CircleWithSlice(startAngle: angle(for: sun?.sunrise ?? .now).degrees, endAngle: angle(for: sun?.sunset ?? .now).degrees)
	}
	
	var sundial: some View {
		ZStack {
			sundialBackground
			phaseSlices
			sundialCenter
		}
	}

	private var sundialBackground: some View {
		background.mask {
			Circle()
				.overlay {
					GeometryReader { g in
						Color.clear.task(id: g.size) {
							size = g.size
						}
						.onAppear {
							size = g.size
						}
					}
				}
		}
		.overlay {
			sundialBorderOverlay
		}
	}

	private var sundialBorderOverlay: some View {
		let borderColor: Color = colorScheme == .dark ? .white : .black.opacity(0.5)
		let borderBlendMode: BlendMode = colorScheme == .dark ? .plusLighter : .plusDarker
		return Circle()
			.fill(.clear)
			.strokeBorder(borderColor, lineWidth: 1)
			.opacity(0.2)
			.blendMode(borderBlendMode)
	}

	private var phaseSlices: some View {
		Group {
			if let phases = sun?.phases {
				let phaseKeys: [Sun.Phase] = Array(phases.keys)
				ForEach(phaseKeys, id: \.self) { key in
					phaseSlice(for: key, phases: phases)
				}
			}
		}
		.aspectRatio(1, contentMode: .fit)
	}

	@ViewBuilder
	private func phaseSlice(for key: Sun.Phase, phases: [Sun.Phase: (sunrise: Date?, sunset: Date?)]) -> some View {
		if let (sunrise, sunset) = phases[key],
			 let sunrise,
			 let sunset {
			CircleWithSlice(startAngle: angle(for: sunrise).degrees, endAngle: angle(for: sunset).degrees)
				.fill(.black.opacity(0.06))
				.blendMode(.plusDarker)

			phaseLines(sunrise: sunrise, sunset: sunset)
		}
	}

	private func phaseLines(sunrise: Date, sunset: Date) -> some View {
		let lineMaskGradient = LinearGradient(
			stops: [
				Gradient.Stop(color: .clear, location: 0.499),
				Gradient.Stop(color: .black, location: 0.5)
			],
			startPoint: .leading,
			endPoint: .trailing
		)

		return Group {
			Rectangle()
				.fill(foregroundStyle.opacity(0.1))
				.frame(height: 1)
				.mask { lineMaskGradient }
				.rotationEffect(angle(for: sunrise))

			Rectangle()
				.fill(foregroundStyle.opacity(0.1))
				.frame(height: 1)
				.mask { lineMaskGradient }
				.rotationEffect(angle(for: sunset))
		}
		.blendMode(blendMode)
	}

	private var sundialCenter: some View {
		ZStack {
			sundialCenterCircle
			aboveHorizonSun
				.reverseMask {
					safeSunriseSunsetShape
				}
			belowHorizonSun
				.mask {
					safeSunriseSunsetShape
				}
		}
		.frame(width: size.width / 1.5, height: size.height / 1.5)
	}

	private var sundialCenterCircle: some View {
		Circle()
			.fill(foregroundStyle.opacity(0.4))
			.mask {
				ZStack {
					Circle()
						.fill(.clear)
						.stroke(.black, lineWidth: 1)
						.padding()

					phaseMarkers
				}
			}
			.blendMode(blendMode)
	}

	@ViewBuilder
	private var phaseMarkers: some View {
		if let phases = sun?.phases {
			let phaseKeys: [Sun.Phase] = Array(phases.keys)
			ForEach(phaseKeys, id: \.self) { key in
				phaseMarker(for: key, phases: phases)
			}
		}
	}

	@ViewBuilder
	private func phaseMarker(for key: Sun.Phase, phases: [Sun.Phase: (sunrise: Date?, sunset: Date?)]) -> some View {
		if let (sunrise, sunset) = phases[key],
			 let sunrise,
			 let sunset {
			Circle()
				.frame(width: minorSunSize)
				.frame(maxWidth: .infinity, alignment: .trailing)
				.padding(.trailing)
				.offset(x: minorSunSize / 2)
				.rotationEffect(angle(for: sunrise))

			Circle()
				.frame(width: minorSunSize)
				.frame(maxWidth: .infinity, alignment: .trailing)
				.padding(.trailing)
				.offset(x: minorSunSize / 2)
				.rotationEffect(angle(for: sunset))
		}
	}
	
	@ViewBuilder
	var labels: some View {
		if let sun {
			ChartLabel(text: Text(sun.safeSunrise, style: .time),
								 imageName: "sunrise",
								 angle: angle(for: sun.safeSunrise))

			ChartLabel(text: Text(sun.safeSunset, style: .time),
								 imageName: "sunset",
								 angle: angle(for: sun.safeSunset))
		}
		
		if let duration = sun?.daylightDuration,
			 let diff = sun?.compactDifferenceString {
			VStack(spacing: 2) {
				HStack(spacing: 2) {
					Image(systemName: "hourglass")
					Text(Duration.seconds(duration).formatted(.units(width: .narrow)))
				}
				
				Text(diff)
					.textScale(.secondary)
					.foregroundStyle(.secondary)
			}
			.padding(4)
			.padding(.horizontal, 4)
			.backportGlassEffect(in: .rect(cornerRadius: 12, style: .continuous))
		}
	}
	
	var body: some View {
			ZStack {
				ZStack {
					sundial
					
					ForEach(0...23, id: \.self) { i in
						RoundedRectangle(cornerRadius: majorSunSize, style: .continuous)
							.fill(foregroundStyle.opacity(0.3))
							.blendMode(blendMode)
							.frame(width: Double(i).remainder(dividingBy: 6) == 0 ? majorSunSize / 1.5 : minorSunSize, height: 2)
							.frame(maxWidth: size.width * 0.9, alignment: .trailing)
							.rotationEffect(Angle(degrees: (360 / 24) * Double(i)))
					}
				}
				#if WIDGET_EXTENSION
				.if(widgetRenderingMode != .fullColor) {
					$0.reverseMask {
						labels
							.backgroundStyle(.black)
					}
				}
				#endif
				
				labels
				#if WIDGET_EXTENSION
					.if(widgetRenderingMode != .fullColor) {
						$0.backgroundStyle(.primary.quinary)
					}
				#endif
			}
			.environment(\.timeZone, timeZone)
			.font(.footnote)
			.fontWeight(.medium)
			.monospacedDigit()
			.frame(maxWidth: .infinity)
			.aspectRatio(1, contentMode: .fit)
			.onChange(of: date ?? timeMachine.date) { _, newDate in
				cachedSun?.setDate(newDate)
			}
			.onChange(of: locationKey) { _, _ in
				cachedSun = Sun(for: date ?? timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
				lastLocationKey = locationKey
			}
			.onAppear {
				if cachedSun == nil || lastLocationKey != locationKey {
					cachedSun = Sun(for: date ?? timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
					lastLocationKey = locationKey
				}
			}
	}
}

fileprivate struct ChartLabel: View {
	var text: Text
	var imageName: String
	var angle: SwiftUI.Angle
	
	var body: some View {
		HStack(spacing: 2) {
			Image(systemName: imageName)
			text
		}
		.padding(4)
		.padding(.horizontal, 2)
		.backportGlassEffect(in: .capsule)
		.rotationEffect(-angle)
		.frame(maxWidth: .infinity, alignment: .trailing)
		.padding(.trailing, -16)
		.rotationEffect(angle)
	}
}

fileprivate struct Helpers {
	static func angle(for date: Date, timeZone: TimeZone = .current) -> SwiftUI.Angle {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		let components = calendar.dateComponents([.hour, .minute, .second], from: date)
		
		let hours = Double(components.hour ?? 0)
		let minutes = Double(components.minute ?? 0)
		let seconds = Double(components.second ?? 0)
		
		let totalSeconds = hours * 3600 + minutes * 60 + seconds
		let fractionOfDay = totalSeconds / 86400 // 24 * 60 * 60
		
		let degrees = fractionOfDay * 360
		return .degrees(degrees + 90) // shift so midnight is at bottom
	}
}

#Preview {
	CircularSolarChart(location: TemporaryLocation.placeholderLondon)
		.padding()
}
