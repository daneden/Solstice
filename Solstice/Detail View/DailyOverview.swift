//
//  DailyOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import SunKit
import Suite
import TimeMachine

struct DailyOverview<Location: AnyLocation>: View {
	@Environment(\.timeMachine) private var timeMachine

	var sun: Sun
	var location: Location
	
	@State private var gradientSun: Sun?
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@AppStorage(Preferences.chartType) private var chartType
	
	var solarDateIsInToday: Bool {
		var calendar = Calendar.autoupdatingCurrent
		calendar.timeZone = location.timeZone
		return calendar.isDate(sun.date, inSameDayAs: Date())
	}
	
	var differenceFromPreviousSolstice: TimeInterval {
		let currentSun = Sun(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
		let previousSolsticeSun = Sun(for: currentSun.date.previousSolstice, coordinate: location.coordinate, timeZone: location.timeZone)

		return previousSolsticeSun.daylightDuration - currentSun.daylightDuration
	}
	
	var nextGreaterThanPrevious: Bool {
		timeMachine.date.nextSolsticeIncreasesLight(at: location.latitude)
	}
	
	var body: some View {
		Section {
			VStack {
				switch chartType {
				#if !os(watchOS)
				case .circular:
					CircularSolarChart(location: location)
						.padding()
						.frame(maxHeight: chartHeight)
						.frame(maxWidth: .infinity)
				#endif
				default:
					daylightChartView
						.frame(height: chartHeight)
						.environment(\.timeZone, location.timeZone)
				}
			}
			.listRowInsets(.zero)
			#if os(watchOS)
			.listRowBackground(Color.clear)
			#else
			.contextMenu {
					Picker(selection: $chartType.animation()) {
						ForEach(ChartType.allCases) { chartType in
							Label(chartType.title, image: chartType.icon)
								.symbolRenderingMode(.hierarchical)
								.imageScale(.large)
								.labelStyle(.titleAndIcon)
						}
					} label: {
						Text("Chart type")
					}
					.pickerStyle(.menu)
					
					Picker(selection: $chartAppearance.animation()) {
						ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
							Label(appearance.description, systemImage: "circle.fill")
								.tint(appearance.tintColor.gradient)
						}
					} label: {
						Text("Chart theme")
					}
					.pickerStyle(.menu)
			}
			.alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }
			.alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
			#if !os(visionOS)
			.listRowBackground(
				sun.view
					.opacity(chartType == .circular && chartAppearance == .graphical ? 0.3 : 0)
					.mask {
						LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
					}
					.background(Color("listRowBackgroundColor"))
			)
			#endif
			#if !os(macOS)
			.menuActionDismissBehavior(.disabled)
			#endif
			#endif
			
			Group {
				Label {
					AdaptiveStack {
						Text(Duration.seconds(sun.daylightDuration).formatted(.units(maximumUnitCount: 2)))
					} label: {
						Text("Total daylight")
					}
				} icon: {
					Image(systemName: "hourglass")
				}
				
				if solarDateIsInToday && (sun.safeSunrise...sun.safeSunset).contains(sun.date) {
					Label {
						AdaptiveStack {
							Text(timerInterval: sun.safeSunrise...sun.safeSunset)
								.monospacedDigit()
						} label: {
							Text("Remaining daylight")
						}
					} icon: {
						Image(systemName: "timer")
					}
				}
				
				Label {
					AdaptiveStack {
						Text(sun.sunrise, style: .time)
					} label: {
						Text("Sunrise")
					}
				} icon: {
					Image(systemName: "sunrise")
				}

				Label {
					AdaptiveStack {
						Text(sun.solarNoon, style: .time)
					} label: {
						Text("Solar noon")
					}
				} icon: {
					Image(systemName: "sun.max")
				}

				Label {
					AdaptiveStack {
						Text(sun.sunset, style: .time)
					} label: {
						Text("Sunset")
					}
				} icon: {
					Image(systemName: "sunset")
				}
			}
			.environment(\.timeZone, location.timeZone)
			.materialListRowBackground()
		} header: {
			if location.timeZoneIdentifier != localTimeZone.identifier,
				 !(location is CurrentLocation) {
				HStack {
					Text("Local time")
					Spacer()
					Text("\(sun.date, style: .time) (\(location.timeZone.differenceStringFromLocalTime(for: timeMachine.date)))")
				}
				.environment(\.timeZone, location.timeZone)
			}
		} footer: {
			Label {
				Text("\(Duration.seconds(abs(differenceFromPreviousSolstice)).formatted(.units(maximumUnitCount: 2))) \(nextGreaterThanPrevious ? "more" : "less") daylight \(timeMachine.dateLabel(context: .middleOfSentence)) compared to the previous solstice")
			} icon: {
				Image(systemName: nextGreaterThanPrevious ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
					.contentTransition(.symbolEffect)
			}
		}
	}
}

extension DailyOverview {
	@ViewBuilder
	var daylightChartView: some View {
		DaylightChart(
			sun: sun,
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
					SkyGradient(sun: gradientSun ?? sun)
				}
		}
		.onPreferenceChange(DaylightGradientTimePreferenceKey.self) { date in
			self.gradientSun = Sun(for: date, coordinate: sun.coordinate)
		}
		#endif
		#if os(macOS)
		.padding(-12)
		#endif
	}
}

#Preview {
	Form {
		DailyOverview(sun: Sun(coordinate: TemporaryLocation.placeholderLondon.coordinate), location: TemporaryLocation.placeholderLondon)
	}
	.withTimeMachine(.solsticeTimeMachine)
}
