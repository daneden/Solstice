//
//  DailyOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar
import Suite
import TimeMachine

struct DailyOverview<Location: AnyLocation>: View {
	@Environment(\.timeMachine) private var timeMachine

	var solar: Solar
	var location: Location
	
	@State private var gradientSolar: Solar?
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@AppStorage(Preferences.chartType) private var chartType
	
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
			VStack {
				switch chartType {
				#if os(iOS)
				case .circular:
					CircularSolarChart(location: location)
						.frame(maxHeight: chartHeight)
						.frame(maxWidth: .infinity)
				#endif
				default:
					daylightChartView
						.frame(height: chartHeight)
						.environment(\.timeZone, location.timeZone)
				}
			}
			#if !os(watchOS)
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
				.pickerStyle(.palette)
				
				Picker(selection: $chartAppearance.animation()) {
					ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
						Label(appearance.description, systemImage: "circle.fill")
							.tint(appearance.tintColor.gradient)
					}
				} label: {
					Text("Appearance")
				}
				.pickerStyle(.palette)
			}
			.alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }
			.alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
			#else
			.listRowBackground(Color.clear)
			#endif
			.listRowInsets(.zero)
			
			Group {
				Label {
					AdaptiveStack {
						Text(Duration.seconds(solar.daylightDuration).formatted(.units(maximumUnitCount: 2)))
					} label: {
						Text("Total daylight")
					}
				} icon: {
					Image(systemName: "hourglass")
				}
				
				if solarDateIsInToday && (solar.safeSunrise...solar.safeSunset).contains(solar.date) {
					Label {
						AdaptiveStack {
							Text(timerInterval: solar.safeSunrise...solar.safeSunset)
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
						if let sunrise = solar.sunrise {
							Text(sunrise, style: .time)
						} else {
							Text("—")
						}
					} label: {
						Text("Sunrise")
					}
				} icon: {
					Image(systemName: "sunrise")
				}
				
				Label {
					AdaptiveStack {
						if let solarNoon = solar.solarNoon {
							Text(solarNoon, style: .time)
						} else {
							Text("—")
						}
					} label: {
						Text("Solar noon")
					}
				} icon: {
					Image(systemName: "sun.max")
				}
				
				Label {
					AdaptiveStack {
						if let sunset = solar.sunset {
							Text(sunset, style: .time)
						} else {
							Text("—")
						}
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
						.contentTransition(.symbolEffect)
				}
			}
		}
	}
}

extension DailyOverview {
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
					SkyGradient(solar: gradientSolar ?? solar)
				}
		}
		.onPreferenceChange(DaylightGradientTimePreferenceKey.self) { date in
			self.gradientSolar = Solar(for: date, coordinate: solar.coordinate)
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
		.withTimeMachine(.solsticeTimeMachine)
	}
}
