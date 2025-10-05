//
//  CircularSolarChart.swift
//  Solstice
//
//  Created by Daniel Eden on 04/10/2025.
//

import SwiftUI
import Solar
import TimeMachine
import Suite
import enum Accelerate.vDSP

struct CircularSolarChart<Location: AnyLocation>: View {
	@Environment(\.colorScheme) private var colorScheme
	@Environment(\.timeMachine) private var timeMachine
	
	@State private var size = CGSize.zero
	
	var location: Location
	
	var timeZone: TimeZone { location.timeZone }
	
	var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: location.coordinate)
	}
	
	var majorSunSize: Double {
		max(16, max(size.width, size.height) * 0.075)
	}
	
	var minorSunSize: Double {
		max(4, majorSunSize / 3)
	}
	
	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		
		return calendar
	}
	
	func angle(for date: Date) -> Angle {
		Helpers.angle(for: date, timeZone: timeZone)
	}
	
	var aboveHorizonSun: some View {
		Circle()
			.fill(.white)
			.frame(width: majorSunSize)
			.frame(maxWidth: .infinity, alignment: .trailing)
			.padding(.trailing, minorSunSize / 2)
			.rotationEffect(angle(for: solar?.date ?? .now))
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	var belowHorizonSun: some View {
		solar?.view.mask {
			Circle()
		}
		.overlay {
			Circle()
				.fill(.clear)
				.strokeBorder(.white, lineWidth: 3)
		}
				.frame(width: majorSunSize)
				.frame(maxWidth: .infinity, alignment: .trailing)
				.padding(.trailing, minorSunSize / 2)
				.rotationEffect(angle(for: solar?.date ?? .now))
				.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	var safeSunriseSunsetShape: some Shape {
		CircleWithSlice(startAngle: angle(for: solar?.sunrise ?? .now).degrees, endAngle: angle(for: solar?.sunset ?? .now).degrees)
	}
	
	var sundial: some View {
		ZStack {
			solar?.view.mask {
				Circle()
					.readSize($size)
			}
			.overlay {
				Circle()
					.fill(.clear)
					.strokeBorder(colorScheme == .dark ? .white : .black.opacity(0.5), lineWidth: 1)
					.opacity(0.2)
					.blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
			}
			
			Group {
				if let phases = solar?.phases {
					ForEach(Array(phases.keys), id: \.self) { key in
						if let (sunrise, sunset) = phases[key],
							 let sunrise,
							 let sunset {
							CircleWithSlice(startAngle: angle(for: sunrise).degrees, endAngle: angle(for: sunset).degrees)
								.fill(.black)
								.opacity(0.06)
								.blendMode(.plusDarker)
						}
					}
				}
			}
			.aspectRatio(1, contentMode: .fit)
			
			ZStack {
				Circle()
					.fill(.white.opacity(0.4))
					.mask {
						ZStack {
							Circle()
								.fill(.clear)
								.stroke(.black, lineWidth: 1)
								.padding()
							
							if let phases = solar?.phases {
								ForEach(Array(phases.keys), id: \.self) { key in
									if let (sunrise, sunset) = phases[key],
										 let sunrise,
										 let sunset {
										Circle()
											.fill(.ultraThinMaterial)
											.frame(width: minorSunSize)
											.frame(maxWidth: .infinity, alignment: .trailing)
											.padding(.trailing)
											.offset(x: minorSunSize / 2)
											.rotationEffect(angle(for: sunrise))
										
										Circle()
											.fill(.ultraThinMaterial)
											.frame(width: minorSunSize)
											.frame(maxWidth: .infinity, alignment: .trailing)
											.padding(.trailing)
											.offset(x: minorSunSize / 2)
											.rotationEffect(angle(for: sunset))
									}
								}
							}
						}
					}
					.blendMode(.plusLighter)
				
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
	}
	
	var body: some View {
			ZStack {
				sundial
					.padding()
					.padding()
				
				ForEach(0...23, id: \.self) { i in
					RoundedRectangle(cornerRadius: majorSunSize, style: .continuous)
						.fill(.white.opacity(0.3))
						.blendMode(.plusLighter)
						.frame(width: Double(i).remainder(dividingBy: 6) == 0 ? majorSunSize / 1.5 : minorSunSize, height: 2)
						.frame(maxWidth: .infinity, alignment: .trailing)
						.padding(.trailing)
						.padding(.trailing)
						.padding(.trailing)
						.rotationEffect(Angle(degrees: (360 / 24) * Double(i)))
				}
				
				if let solar {
					ChartLabel(text: Text(solar.safeSunrise, style: .time),
										 imageName: "sunrise",
										 angle: angle(for: solar.safeSunrise))
					
					ChartLabel(text: Text(solar.safeSunset, style: .time),
										 imageName: "sunrise",
										 angle: angle(for: solar.safeSunset))
				}
				
				if let duration = solar?.daylightDuration,
					 let diff = solar?.compactDifferenceString {
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
					.contentTransition(.numericText())
					.animation(.snappy, value: timeMachine.date)
				}
			}
			.environment(\.timeZone, timeZone)
			.font(.footnote)
			.fontWeight(.medium)
			.monospacedDigit()
			.frame(maxWidth: .infinity)
			.aspectRatio(1, contentMode: .fit)
	}
}

struct CircleWithSlice: Shape {
	var startAngle: Double // degrees
	var endAngle: Double // degrees
	
	var animatableData: AnimatablePair<Double, Double> {
		get { AnimatablePair(startAngle, endAngle) }
		set {
			startAngle = newValue.first
			endAngle = newValue.second
		}
	}
	
	func path(in rect: CGRect) -> Path {
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = min(rect.width, rect.height) / 2
		
		var path = Path()
		
		// Draw the full circle
		path.addEllipse(in: rect)
		
		// Create the slice path
		var slice = Path()
		slice.move(to: center)
		slice.addArc(center: center,
								 radius: radius,
								 startAngle: Angle(degrees: startAngle),
								 endAngle: Angle(degrees: endAngle),
								 clockwise: false)
		slice.closeSubpath()
		
		// Subtract the slice from the circle
		path.addPath(slice, transform: .identity)
		return path
			.subtracting(slice) // requires iOS 17+ (Shape subtraction!)
	}
}

fileprivate struct ChartLabel: View {
	var text: Text
	var imageName: String
	var angle: Angle
	
	var body: some View {
		HStack(spacing: 2) {
			Image(systemName: imageName)
			text
				.contentTransition(.numericText())
		}
		.padding(4)
		.backportGlassEffect(in: .capsule)
		.rotationEffect(-angle)
		.frame(maxWidth: .infinity, alignment: .trailing)
		.padding()
		.rotationEffect(angle)
	}
}

fileprivate struct Helpers {
	static func angle(for date: Date, timeZone: TimeZone = .current) -> Angle {
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

extension View {
	@inlinable
	public func reverseMask<Mask: View>(
		alignment: Alignment = .center,
		@ViewBuilder _ mask: () -> Mask
	) -> some View {
		self.mask {
			Rectangle()
				.overlay(alignment: alignment) {
					mask()
						.blendMode(.destinationOut)
				}
		}
	}
}

extension View {
	func backportGlassEffect<S: Shape>(in shape: S) -> some View {
		if #available(iOS 26, macOS 26, watchOS 26, *) {
			return glassEffect(in: shape)
		} else {
			return background(.regularMaterial, in: shape).shadow(color: .black.opacity(0.1), radius: 8, y: 4)
		}
	}
}


#Preview {
	CircularSolarChart(location: TemporaryLocation.placeholderLondon)
		.timeMachineOverlay()
		.withTimeMachine(.solsticeTimeMachine)
}

