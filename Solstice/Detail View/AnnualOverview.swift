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
	@State var detailedDaylightInformationVisible = false
	#if os(macOS)
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
	
	var detailedDaylightTransition: some Transition {
		AsymmetricTransition(insertion: .move(edge: .top), removal: .move(edge: .bottom)).combined(with: .opacity)
	}
	
	var body: some View {
		Section {
			AdaptiveLabeledContent {
				Text(solsticeAndEquinoxFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
					.contentTransition(.numericText())
			} label: {
				Label("Next Solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
					.contentTransition(.symbolEffect)
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
			
			if let differenceFromPreviousSolstice {
				Label {
					Text("\(Duration.seconds(abs(differenceFromPreviousSolstice)).formatted(.units(maximumUnitCount: 2))) \(nextGreaterThanPrevious ? "more" : "less") daylight \(timeMachine.targetDateLabel(formattingContext: .middleOfSentence)) compared to the previous solstice")
						.id(timeMachine.targetDate)
				} icon: {
					Image(systemName: nextGreaterThanPrevious ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
						.contentTransition(.symbolEffect)
				}
			}
			
			AdaptiveLabeledContent {
				Text(solsticeAndEquinoxFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
					.contentTransition(.numericText())
			} label: {
				Text(nextEquinox, style: .date)
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
		} header: {
			Label("Next Equinox", systemImage: "circle.and.line.horizontal")
		}
		
		if let shortestDay,
			 let longestDay {
			let longestDayDuration = Duration.seconds(longestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
			let shortestDayDuration = Duration.seconds(shortestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
			
			AnnualDaylightChart(location: location)
				.frame(height: chartHeight)
			
			if let shortestDay,
				 let longestDay {
				
				Group {
					StackedLabeledContent {
						let duration = Duration.seconds(longestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						
						if detailedDaylightInformationVisible {
							Text("\(duration) of daylight")
								.transition(detailedDaylightTransition)
						} else {
							Text(longestDay.date, style: .date)
								.transition(detailedDaylightTransition)
						}
					} label: {
						Label("Longest Day", systemImage: "sun.max")
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
						
						if detailedDaylightInformationVisible {
							Text("\(duration) of daylight")
								.transition(detailedDaylightTransition)
						} else {
							Text(shortestDay.date, style: .date)
								.transition(detailedDaylightTransition)
						}
					} label: {
						Label("Shortest Day", systemImage: "sun.min")
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
				.onTapGesture {
					detailedDaylightInformationVisible.toggle()
				}
				.animation(.default, value: detailedDaylightInformationVisible)
			}
			
			Section { } footer: {
#if !os(watchOS)
				Button {
#if os(macOS)
					openWindow.callAsFunction(id: "about-equinox-and-solstice")
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
						EquinoxAndSolsticeInfoView()
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
