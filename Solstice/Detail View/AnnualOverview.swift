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
	#if os(macOS)
	@Environment(\.openWindow) var openWindow
	#endif
	@EnvironmentObject var timeMachine: TimeMachine
	
	@State private var isInformationSheetPresented = false
	
	var differenceFromPreviousSolstice: TimeInterval? {
		guard let solar = Solar(for: timeMachine.date, coordinate: location.coordinate),
					let previousSolsticeSolar = Solar(for: solar.date.previousSolstice, coordinate: location.coordinate) else {
			return nil
		}
		
		return previousSolsticeSolar.daylightDuration - solar.daylightDuration
	}
	
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
			VStack(alignment: .leading) {
				AdaptiveLabeledContent {
					Text(solsticeAndEquinoxFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
				} label: {
					Label("Next Solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
				}
				
				if let differenceFromPreviousSolstice {
					Label {
						Text("\(Duration.seconds(abs(differenceFromPreviousSolstice)).formatted(.units(maximumUnitCount: 2))) \(nextGreaterThanPrevious ? "more" : "less") daylight on this day compared to the previous solstice")
							.font(.footnote)
							.foregroundStyle(.secondary)
					} icon: {
						Color.clear.frame(width: 0, height: 0)
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
				Text(solsticeAndEquinoxFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
			} label: {
				Label("Next Equinox", systemImage: "circle.and.line.horizontal")
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
			
			AnnualDaylightChart(location: location)
				.frame(height: chartHeight)
			
			if let shortestDay,
				 let longestDay {
				
				VStack(alignment: .leading) {
					let duration = Duration.seconds(longestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
					
					AdaptiveLabeledContent {
						Text(longestDay.date, style: .date)
					} label: {
						Label("Longest Day", systemImage: "sun.max")
					}
					
					Label {
						Text("\(duration) of daylight")
							.font(.footnote)
							.foregroundStyle(.secondary)
					} icon: {
						Color.clear.frame(width: 0, height: 0)
					}
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
				
				VStack(alignment: .leading) {
					let duration = Duration.seconds(shortestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
					
					AdaptiveLabeledContent {
						Text(shortestDay.date, style: .date)
					} label: {
						Label("Shortest Day", systemImage: "sun.min")
					}
					
					Label {
						Text("\(duration) of daylight")
							.font(.footnote)
							.foregroundStyle(.secondary)
					} icon: {
						Color.clear.frame(width: 0, height: 0)
					}
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

struct AnnualOverview_Previews: PreviewProvider {
	static var previews: some View {
		Form {
			TimeMachineView()
			AnnualOverview(location: TemporaryLocation.placeholderLondon)
		}
		.environmentObject(TimeMachine.preview)
	}
}
