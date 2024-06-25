//
//  DailyOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar

struct DailyOverview<Location: AnyLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine

	var solar: Solar
	var location: Location
	
	@State var chartRenderedAsImage: Image?
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	
	var solarDateIsInToday: Bool {
		var calendar = Calendar.autoupdatingCurrent
		calendar.timeZone = location.timeZone
		return calendar.isDate(solar.date, inSameDayAs: Date())
	}
	
	var differenceFromPreviousSolstice: TimeInterval? {
		guard let solar = Solar(for: timeMachine.date, coordinate: location.coordinate),
					let previousSolsticeSolar = Solar(for: solar.date.previousSolstice, coordinate: location.coordinate) else {
			return nil
		}
		
		return previousSolsticeSolar.daylightDuration - solar.daylightDuration
	}
	
	var nextSolsticeMonth: Int {
		calendar.dateComponents([.month], from: timeMachine.date.nextSolstice).month ?? 6
	}
	
	var nextGreaterThanPrevious: Bool {
		switch nextSolsticeMonth {
		case 6:
			return location.latitude > 0
		case 12:
			return location.latitude < 0
		default:
			return true
		}
	}
	
	var body: some View {
		Section {
			daylightChartView
				.frame(height: chartHeight)
				#if !os(watchOS)
				.contextMenu {
					if let chartRenderedAsImage {
						var locationTitle: Text {
							guard let title = location.title else {
								return Text("my location")
							}
							
							return Text(title)
						}
						
						ShareLink(
							item: chartRenderedAsImage,
							preview: SharePreview("Daylight in \(locationTitle)", image: chartRenderedAsImage)
						)
					}

					Picker(selection: $chartAppearance.animation()) {
						ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
							Text(appearance.description)
						}
					} label: {
						Label("Appearance", systemImage: "paintpalette")
					}
				}
				#endif
				.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
				#if os(watchOS)
				.listRowBackground(Color.clear)
				#endif
				.environment(\.timeZone, location.timeZone)
			
			Group {
				AdaptiveLabeledContent {
					Text(Duration.seconds(solar.daylightDuration).formatted(.units(maximumUnitCount: 2)))
						.contentTransition(.numericText())
				} label: {
					Label("Total daylight", systemImage: "hourglass")
				}
				
				if solarDateIsInToday && (solar.safeSunrise...solar.safeSunset).contains(solar.date) {
					AdaptiveLabeledContent {
						Text(timerInterval: solar.safeSunrise...solar.safeSunset)
							.monospacedDigit()
					} label: {
						Label("Remaining daylight", systemImage: "timer")
					}
				}
				
				AdaptiveLabeledContent {
					if let sunrise = solar.fallbackSunrise {
						Text(sunrise, style: .time)
					} else {
						Text("—")
					}
				} label: {
					Label("Sunrise", systemImage: "sunrise")
				}
				
				AdaptiveLabeledContent {
					if let solarNoon = solar.solarNoon {
						Text(solarNoon, style: .time)
					} else {
						Text("—")
					}
				} label: {
					Label("Solar noon", systemImage: "sun.max")
				}
				
				AdaptiveLabeledContent {
					if let sunset = solar.fallbackSunset {
						Text(sunset, style: .time)
					} else {
						Text("—")
					}
				} label: {
					Label("Sunset", systemImage: "sunset")
				}
			}
			.environment(\.timeZone, location.timeZone)
			.animation(.default, value: timeMachine.date)
			.contentTransition(.numericText())
		} header: {
			if location.timeZoneIdentifier != localTimeZone.identifier,
				 !(location is CurrentLocation) {
				HStack {
					Text("Local time")
					Spacer()
					Text("\(solar.date, style: .time) (\(location.timeZone.differenceStringFromLocalTime(for: timeMachine.date)))")
				}
				.environment(\.timeZone, location.timeZone)
			}
		} footer: {
			if let differenceFromPreviousSolstice {
				Label {
					Text("\(Duration.seconds(abs(differenceFromPreviousSolstice)).formatted(.units(maximumUnitCount: 2))) \(nextGreaterThanPrevious ? "more" : "less") daylight \(timeMachine.dateLabel(context: .middleOfSentence)) compared to the previous solstice")
				} icon: {
					Image(systemName: nextGreaterThanPrevious ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
						.modify { content in
							if #available(iOS 17, macOS 14, watchOS 10, *) {
								content
									.contentTransition(.symbolEffect)
							} else {
								content
							}
						}
				}
			}
		}
		.task(id: timeMachine.date, priority: .background) {
			chartRenderedAsImage = buildChartRenderedAsImage()
		}
	}
}

extension DailyOverview {
	func buildChartRenderedAsImage() -> Image? {
		let view = VStack {
			HStack {
				Label("Solstice", image: "Solstice.SFSymbol")
					.font(.headline)
				
				Spacer()
			}
			.padding()
			
			daylightChartView
				.clipShape(
					RoundedRectangle(
						cornerRadius: 16,
						style: .continuous
					)
				)
				.if(chartAppearance == .graphical) { view in
					view.padding(.horizontal)
				}
			
			
			HStack {
				VStack(alignment: .leading) {
					Group {
						if let title = location.title {
							Text(title)
						} else {
							Text("Current Location")
						}
					}
					.font(.headline)
					
					let duration = solar.daylightDuration.localizedString
					Text("\(duration) of daylight")
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				VStack(alignment: .trailing) {
					Text("Sunrise: \(solar.safeSunrise, style: .time)")
					
					Text("Sunset: \(solar.safeSunset, style: .time)")
				}
				.foregroundStyle(.secondary)
			}
			.padding()
		}
			.background(.black)
			.foregroundStyle(.white)
			.clipShape(
				RoundedRectangle(
					cornerRadius: 20,
					style: .continuous
				)
			)
			.frame(width: 540, height: 720)
		
		let imageRenderer = ImageRenderer(content: view)
		imageRenderer.scale = 3
		imageRenderer.isOpaque = false
#if os(macOS)
		guard let image = imageRenderer.nsImage else {
			return nil
		}
		
		return Image(nsImage: image)
#else
		guard let image = imageRenderer.uiImage else {
			return nil
		}
		
		return Image(uiImage: image)
#endif
	}
	
	@ViewBuilder
	var daylightChartView: some View {
		DaylightChart(
			solar: solar,
			timeZone: location.timeZone,
			appearance: chartAppearance, scrubbable: true,
			markSize: chartMarkSize
		)
		#if os(macOS)
		.padding(12)
		#endif
		#if !os(watchOS)
		.if(chartAppearance == .graphical) { content in
			content
				.background {
					SkyGradient(solar: solar)
				}
		}
		#endif
		#if os(macOS)
		.padding(-12)
		#endif
	}
}

struct DailyOverview_Previews: PreviewProvider {
	static var previews: some View {
		Form {
			DailyOverview(solar: Solar(coordinate: TemporaryLocation.placeholderLondon.coordinate)!, location: TemporaryLocation.placeholderLondon)
		}
		.environmentObject(TimeMachine.preview)
	}
}
