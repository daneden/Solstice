//
//  DailyOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import Suite
import SwiftUI
import TimeMachine

struct DailyOverview<Location: AnyLocation>: View {
	@Environment(\.timeMachine) private var timeMachine

	var solar: NTSolar
	var location: Location

	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@AppStorage(Preferences.chartType) private var chartType
	@AppStorage(Preferences.bodyMode) private var bodyMode

	/// The moon for the displayed day, or `nil` while it is still being worked out.
	/// Owned by `DetailView` so the search is cached rather than repeated on every body
	/// evaluation.
	var moon: LunarCalculator.Moon? = nil

	var solarDateIsInToday: Bool {
		var calendar = Calendar.autoupdatingCurrent
		calendar.timeZone = location.timeZone
		return calendar.isDate(solar.date, inSameDayAs: Date())
	}

	var differenceFromPreviousSolstice: TimeInterval? {
		guard let solar = NTSolar(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone),
		      let previousSolsticeSolar = NTSolar(for: solar.date.previousSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
		else {
			return nil
		}

		return previousSolsticeSolar.daylightDuration - solar.daylightDuration
	}

	var nextGreaterThanPrevious: Bool {
		timeMachine.date.nextSolsticeIncreasesLight(at: location.latitude)
	}

	var body: some View {
		// Two sections rather than one: the chart and the sun above, the moon below.
		// Interleaving them made the two bodies’ times read as a single list.
		Group {
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
							solar.view
								.opacity(chartType == .circular && chartAppearance == .graphical ? 0.3 : 0)
								.mask {
									LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
								}
								.background(Color("listRowBackgroundColor"))
						)
					#endif
				#endif

				if bodyMode.includesSun {
					Group {
						solarRows
					}
					.environment(\.timeZone, location.timeZone)
					.materialListRowBackground()
				}
			} header: {
				if location.timeZoneIdentifier != localTimeZone.identifier,
				   !(location is CurrentLocation)
				{
					HStack {
						Text("Local time")
						Spacer()
						Text("\(solar.date, style: .time) (\(location.timeZone.differenceStringFromLocalTime(for: timeMachine.date)))")
					}
					.environment(\.timeZone, location.timeZone)
				}
			} footer: {
				if let differenceFromPreviousSolstice {
					let moreOrLess = nextGreaterThanPrevious
						? String(localized: "more", comment: "More daylight middle of sentence")
						: String(localized: "less", comment: "Less daylight middle of sentence")
					Label {
						Text("\(Duration.seconds(abs(differenceFromPreviousSolstice)).formatted(.units(maximumUnitCount: 2))) \(moreOrLess) daylight \(timeMachine.dateLabel(context: .middleOfSentence)) compared to the previous solstice")
					} icon: {
						Image(systemName: nextGreaterThanPrevious ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
							.contentTransition(.symbolEffect)
					}
				}
			}

			if bodyMode.includesMoon, let moon {
				Section {
					Group {
						lunarRows(for: moon)
					}
					.environment(\.timeZone, location.timeZone)
					.materialListRowBackground()
				}
			}
		}
	}

	@ViewBuilder
	private var solarRows: some View {
		Label {
			AdaptiveStack {
				Text(Duration.seconds(solar.daylightDuration).formatted(.units(maximumUnitCount: 2)))
			} label: {
				Text("Total daylight")
			}
		} icon: {
			Image(systemName: "hourglass")
		}

		if solarDateIsInToday && (solar.safeSunrise ... solar.safeSunset).contains(solar.date) {
			Label {
				AdaptiveStack {
					if let pinned = ScreenshotLaunch.displayDate {
						// Text(timerInterval:) counts down against the real system clock,
						// which a pinned capture must not leak; show the same remaining
						// duration measured from the pinned instant instead.
						Text(Duration.seconds(max(0, solar.safeSunset.timeIntervalSince(pinned)))
							.formatted(.time(pattern: .hourMinuteSecond)))
							.monospacedDigit()
					} else {
						Text(timerInterval: solar.safeSunrise ... solar.safeSunset)
							.monospacedDigit()
					}
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

	/// The lunar counterpart of the solar rows. Moonrise and moonset are optional in a way
	/// sunrise and sunset are not: the moon rises roughly 50 minutes later each day, so
	/// about once a lunation a calendar day simply has no moonrise, or no moonset. That is
	/// ordinary everywhere, not a polar edge case, and it renders as an em dash.
	@ViewBuilder
	private func lunarRows(for moon: LunarCalculator.Moon) -> some View {
		Label {
			AdaptiveStack {
				Text(moon.formattedIllumination)
			} label: {
				Text(moon.phase.localizedName)
			}
		} icon: {
			// No `contentTransition` here: the glyph changes whenever the moon data
			// arrives, which is on every day change, so the symbol effect fired far more
			// often than it looked like it would.
			Image(systemName: moon.phase.symbolName(latitude: location.latitude))
		}

		Label {
			AdaptiveStack {
				if let moonrise = moon.moonrise {
					Text(moonrise, style: .time)
				} else {
					Text("—")
				}
			} label: {
				Text("Moonrise")
			}
		} icon: {
			Image(systemName: "moonrise")
		}

		Label {
			AdaptiveStack {
				if let moonset = moon.moonset {
					Text(moonset, style: .time)
				} else {
					Text("—")
				}
			} label: {
				Text("Moonset")
			}
		} icon: {
			Image(systemName: "moonset")
		}
	}

}

extension DailyOverview {
	/// Whether the chart gets the sky background and coordinate space (and so should publish its
	/// geometry): graphical appearance on platforms where the background block below compiles.
	private var isGraphicalWithSkyBackground: Bool {
		#if os(watchOS)
			return false
		#else
			return chartAppearance == .graphical
		#endif
	}

	@ViewBuilder
	var daylightChartView: some View {
		DaylightChart(
			solar: solar,
			moon: moon,
			timeZone: location.timeZone,
			appearance: chartAppearance, scrubbable: true,
			markSize: chartMarkSize,
			// Must mirror the condition that attaches the coordinate space below.
			tracksSkyGeometry: isGraphicalWithSkyBackground
		)
		#if os(macOS)
		.padding(12)
		#endif
		#if !os(watchOS)
		.if(chartAppearance == .graphical) { content in
			content.skyChartBackground(solar: solar)
		}
		#endif
		#if os(macOS)
		.padding(-12)
		#endif
	}
}

#Preview {
	Form {
		DailyOverview(solar: NTSolar(for: .now, coordinate: TemporaryLocation.placeholderLondon.coordinate, timeZone: TemporaryLocation.placeholderLondon.timeZone)!, location: TemporaryLocation.placeholderLondon)
	}
	.withTimeMachine(.solsticeTimeMachine)
}
