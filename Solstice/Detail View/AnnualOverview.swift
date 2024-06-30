//
//  AnnualOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar

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
	@EnvironmentObject var timeMachine: TimeMachine
	
	@State private var isInformationSheetPresented = false
	
	var location: Location
	
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
	
	var date: Date { timeMachine.date }
	var nextSolstice: Date { timeMachine.date.nextSolstice }
	var nextEquinox: Date { timeMachine.date.nextEquinox }
	
	var body: some View {
		Section {
			Group {
				AdaptiveLabeledContent {
					ContentToggle { showContent in
						if showContent {
							Text(nextSolstice.startOfDay, style: .date)
						} else {
							Text(solsticeAndEquinoxFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
								.contentTransition(.numericText())
						}
					}
				} label: {
					Label("Next solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
						.modify { content in
							if #available(iOS 17, macOS 14, watchOS 10, *) {
								content
									.contentTransition(.symbolEffect)
							} else {
								content
							}
						}
				}
				.swipeActions(edge: .leading) {
					Button {
						withAnimation {
							timeMachine.isOn = true
							timeMachine.targetDate = nextSolstice
						}
					} label: {
						Label("Jump to \(nextSolstice, style: .date)", systemImage: "clock.arrow.2.circlepath")
					}
				}
				
				AdaptiveLabeledContent {
					ContentToggle { showContent in
						if showContent {
							Text(nextEquinox, style: .date)
						} else {
							Text(solsticeAndEquinoxFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
								.contentTransition(.numericText())
						}
					}
				} label: {
					Label("Next equinox", systemImage: "circle.and.line.horizontal")
				}
				.swipeActions(edge: .leading) {
					Button {
						withAnimation {
							timeMachine.isOn = true
							timeMachine.targetDate = nextEquinox
						}
					} label: {
						Label("Jump to \(nextEquinox, style: .date)", systemImage: "clock.arrow.2.circlepath")
					}
					.backgroundStyle(.tint)
				}
			}
			.animation(.default, value: timeMachine.date)
			.contentTransition(.numericText())
			
			AnnualDaylightChart(location: location)
				.frame(height: chartHeight)
			
			if let shortestDay,
				 let longestDay {
					StackedLabeledContent {
						let duration = Duration.seconds(longestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						
						ContentToggle { showContent in
							if showContent {
								Text("\(duration) of daylight")
							} else {
								Text(longestDay.date, style: .date)
							}
						}
					} label: {
						Label("Longest day", systemImage: "sun.max")
					}
					.swipeActions(edge: .leading) {
						Button {
							withAnimation {
								timeMachine.isOn = true
								timeMachine.targetDate = longestDay.date
							}
						} label: {
							Label("Jump to \(longestDay.date, style: .date)", systemImage: "clock.arrow.2.circlepath")
						}
					}
					
					StackedLabeledContent {
						let duration = Duration.seconds(shortestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						
						ContentToggle { showContent in
							if showContent {
								Text("\(duration) of daylight")
							} else {
								Text(shortestDay.date, style: .date)
							}
						}
					} label: {
						Label("Shortest day", systemImage: "sun.min")
					}
					.swipeActions(edge: .leading) {
						Button {
							withAnimation {
								timeMachine.isOn = true
								timeMachine.targetDate = shortestDay.date
							}
						} label: {
							Label("Jump to \(shortestDay.date, style: .date)", systemImage: "clock.arrow.2.circlepath")
						}
					}
			}
		} footer: {
#if !os(watchOS)
			Button {
				#if os(macOS)
				openWindow.callAsFunction(id: "about-equinox-and-solstice")
				#elseif os(visionOS)
				openWindow(value: AnnualSolarEvent.juneSolstice)
				#else
				isInformationSheetPresented = true
				#endif
			} label: {
				Label("Learn more about the equinox and solstice", systemImage: "info.circle")
					.font(.footnote)
			}
			.buttonStyle(.automatic)
			.sheet(isPresented: $isInformationSheetPresented) {
				NavigationStack {
					EquinoxAndSolsticeInfoSheet()
#if os(macOS)
						.frame(minWidth: 500, minHeight: 500)
#endif
						.toolbar {
							Button("Close") {
								isInformationSheetPresented = false
							}
						}
				}
			}
#endif
		}
		.buttonStyle(.plain)
	}
}

extension AnnualOverview {
	var decemberSolsticeSolar: Solar? {
		let year = calendar.component(.year, from: timeMachine.date)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		return Solar(for: decemberSolstice, coordinate: location.coordinate)
	}
	
	var juneSolsticeSolar: Solar? {
		let year = calendar.component(.year, from: timeMachine.date)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		return Solar(for: juneSolstice, coordinate: location.coordinate)
	}
	
	var longestDay: Solar? {
		guard let decemberSolsticeSolar,
					let juneSolsticeSolar else {
			return nil
		}
		
		return decemberSolsticeSolar.daylightDuration > juneSolsticeSolar.daylightDuration ? decemberSolsticeSolar : juneSolsticeSolar
	}
	
	var shortestDay: Solar? {
		guard let decemberSolsticeSolar,
					let juneSolsticeSolar else {
			return nil
		}
		
		return decemberSolsticeSolar.daylightDuration < juneSolsticeSolar.daylightDuration ? decemberSolsticeSolar : juneSolsticeSolar
	}
}

#Preview {
	Form {
		TimeMachineView()
		AnnualOverview(location: TemporaryLocation.placeholderLondon)
	}
	.environmentObject(TimeMachine.preview)
}
