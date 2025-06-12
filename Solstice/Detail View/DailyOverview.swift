//
//  DailyOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar
import Suite

struct DailyOverview<Location: AnyLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine

	var solar: Solar
	var location: Location
	
	@State private var showShareSheet = false
	@State private var gradientSolar: Solar?
	
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
					#if !os(macOS)
					Button("Share...", systemImage: "square.and.arrow.up") {
						showShareSheet.toggle()
					}
					#endif

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
				#if !os(watchOS)
				.sheet(isPresented: $showShareSheet) {
					ShareSolarChartView(solar: solar, location: location, chartAppearance: chartAppearance)
				}
				#endif
			
			Group {
				AdaptiveLabeledContent {
					Text(Duration.seconds(solar.daylightDuration).formatted(.units(maximumUnitCount: 2)))
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
					if let sunrise = solar.sunrise {
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
					if let sunset = solar.sunset {
						Text(sunset, style: .time)
					} else {
						Text("—")
					}
				} label: {
					Label("Sunset", systemImage: "sunset")
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
		.environmentObject(TimeMachine.preview)
	}
}
