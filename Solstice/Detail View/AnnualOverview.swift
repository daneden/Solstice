//
//  AnnualOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import SunKit
import Suite
import TimeMachine

fileprivate var solsticeAndEquinoxFormatter: RelativeDateTimeFormatter {
	let formatter = RelativeDateTimeFormatter()
	formatter.unitsStyle = .full
	formatter.dateTimeStyle = .named
	return formatter
}

struct AnnualOverview<Location: AnyLocation>: View {
	#if !os(watchOS)
	@Environment(\.openWindow) var openWindow
	#endif
	@Environment(\.timeMachine) var timeMachine: TimeMachine

	@State private var isInformationSheetPresented = false
	@State private var cachedDecemberSolsticeSun: Sun?
	@State private var cachedJuneSolsticeSun: Sun?

	var location: Location
	
	var nextGreaterThanPrevious: Bool {
		timeMachine.date.nextSolsticeIncreasesLight(at: location.latitude)
	}
	
	var date: Date { timeMachine.date }
	var nextSolstice: Date { timeMachine.date.nextSolstice }
	var nextEquinox: Date { timeMachine.date.nextEquinox }
	
	var body: some View {
		Section {
			Group {
				Label {
					AdaptiveStack {
						ContentToggle { showContent in
							if showContent {
								Text(nextSolstice.startOfDay, style: .date)
							} else {
								Text(solsticeAndEquinoxFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
							}
						}
					} label: {
						Text("Next solstice")
					}
				} icon: {
					Image(systemName: nextGreaterThanPrevious ? "sun.max" : "sun.min")
						.contentTransition(.symbolEffect)
				}
				.swipeActions(edge: .leading) {
					Button {
						withAnimation {
							timeMachine.date = nextSolstice
						}
					} label: {
						Label("Jump to date", systemImage: "clock.arrow.2.circlepath")
					}
				}
				
				Label {
					AdaptiveStack {
						ContentToggle { showContent in
							if showContent {
								Text(nextEquinox, style: .date)
							} else {
								Text(solsticeAndEquinoxFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
							}
						}
					} label: {
						Text("Next equinox")
					}
				} icon: {
					Image(systemName: "circle.and.line.horizontal")
				}
				.swipeActions(edge: .leading) {
					Button {
						withAnimation {
							timeMachine.date = nextEquinox
						}
					} label: {
						Label("Jump to date", systemImage: "clock.arrow.2.circlepath")
					}
					.backgroundStyle(.tint)
				}
			}
			
			AnnualDaylightChart(location: location)
				.frame(height: chartHeight)
			
			if let shortestDay,
				 let longestDay {
					Label {
						let duration = Duration.seconds(longestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						
						AdaptiveStack {
							ContentToggle { showContent in
								if showContent {
									Text("\(duration) of daylight")
								} else {
									Text(longestDay.date, style: .date)
								}
							}
						} label: {
							Text("Longest day")
						}
					} icon: {
						Image(systemName: "sun.max")
					}
					.swipeActions(edge: .leading) {
						Button {
							withAnimation {
								timeMachine.date = longestDay.date
							}
						} label: {
							Label("Jump to date", systemImage: "clock.arrow.2.circlepath")
						}
					}
					
					Label {
						let duration = Duration.seconds(shortestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						
						AdaptiveStack {
							ContentToggle { showContent in
								if showContent {
									Text("\(duration) of daylight")
								} else {
									Text(shortestDay.date, style: .date)
								}
							}
						} label: {
							Text("Shortest day")
						}
					} icon: {
						Image(systemName: "sun.min")
					}
					.swipeActions(edge: .leading) {
						Button {
							withAnimation {
								timeMachine.date = shortestDay.date
							}
						} label: {
							Label("Jump to date", systemImage: "clock.arrow.2.circlepath")
						}
					}
			}
			
			if let daylightSavingsChange = location.timeZone.nextDaylightSavingTimeTransition(after: timeMachine.date) {
				Label {
					AdaptiveStack {
						Text(daylightSavingsChange, style: .date)
					} label: {
						if location.timeZone.isDaylightSavingTime(for: timeMachine.date) {
							Text("Daylight savings ends")
						} else {
							Text("Daylight savings begins")
						}
					}
				} icon: {
					Image(.daylightsavings)
						.imageScale(.large)
				}
			}
		}
		.materialListRowBackground()
		.task(id: solsticeDependencies) {
			updateSolsticeSuns()
		}
	}
}

extension AnnualOverview {
	var decemberSolsticeSun: Sun? { cachedDecemberSolsticeSun }
	var juneSolsticeSun: Sun? { cachedJuneSolsticeSun }

	var longestDay: Sun? {
		guard let decemberSolsticeSun,
					let juneSolsticeSun else {
			return nil
		}
		return decemberSolsticeSun.daylightDuration > juneSolsticeSun.daylightDuration ? decemberSolsticeSun : juneSolsticeSun
	}

	var shortestDay: Sun? {
		guard let decemberSolsticeSun,
					let juneSolsticeSun else {
			return nil
		}
		return decemberSolsticeSun.daylightDuration < juneSolsticeSun.daylightDuration ? decemberSolsticeSun : juneSolsticeSun
	}

	var solsticeDependencies: [AnyHashable] {
		let year = calendar.component(.year, from: timeMachine.date)
		return [year, location.coordinate.latitude, location.coordinate.longitude]
	}

	func updateSolsticeSuns() {
		let year = calendar.component(.year, from: timeMachine.date)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		cachedDecemberSolsticeSun = Sun(for: decemberSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
		cachedJuneSolsticeSun = Sun(for: juneSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
	}
}

#Preview {
	Form {
		TimeMachineView() { Text("Time Machine") }
		AnnualOverview(location: TemporaryLocation.placeholderLondon)
	}
	.withTimeMachine(.solsticeTimeMachine)
}
