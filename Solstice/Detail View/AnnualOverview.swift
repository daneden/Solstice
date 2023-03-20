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
	@EnvironmentObject var timeMachine: TimeMachine
	
	var differenceFromPreviousSolstice: TimeInterval? {
		guard let solar = Solar(for: timeMachine.date, coordinate: location.coordinate.coordinate),
					let previousSolsticeSolar = Solar(for: solar.date.previousSolstice, coordinate: location.coordinate.coordinate) else {
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
			Button {
				withAnimation {
					timeMachine.isOn = true
					timeMachine.targetDate = nextSolstice
				}
			} label: {
				VStack(alignment: .leading) {
					AdaptiveLabeledContent {
						Text(solsticeAndEquinoxFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
					} label: {
						Label("Next Solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
					}
					
					if let differenceFromPreviousSolstice {
						Label {
							Text("\(Duration.seconds(abs(differenceFromPreviousSolstice)).formatted(.units(maximumUnitCount: 2))) \(nextGreaterThanPrevious ? "more" : "less") daylight on this day compared to the previous solstice")
								.font(.caption)
								.foregroundStyle(.secondary)
						} icon: {
							Color.clear.frame(width: 0, height: 0)
						}
					}
				}
			}
			
			Button {
				withAnimation {
					timeMachine.isOn = true
					timeMachine.targetDate = nextEquinox
				}
			} label: {
				AdaptiveLabeledContent {
					Text(solsticeAndEquinoxFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
				} label: {
					Label("Next Equinox", systemImage: "circle.and.line.horizontal")
				}
			}
			
			AnnualDaylightChart(location: location)
				.frame(height: chartHeight)
			
			if let shortestDay,
				 let longestDay {
				Button {
					withAnimation {
						timeMachine.isOn = true
						timeMachine.targetDate = longestDay.date
					}
				} label: {
					AdaptiveLabeledContent {
						let duration = Duration.seconds(longestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						Text("\(longestDay.date, style: .date) (\(duration))")
					} label: {
						Label("Longest Day", systemImage: "sun.max")
					}
				}
				
				Button {
					withAnimation {
						timeMachine.isOn = true
						timeMachine.targetDate = shortestDay.date
					}
				} label: {
					AdaptiveLabeledContent {
						let duration = Duration.seconds(shortestDay.daylightDuration).formatted(.units(maximumUnitCount: 2))
						Text("\(shortestDay.date, style: .date) (\(duration))")
					} label: {
						Label("Shortest Day", systemImage: "sun.min")
					}
				}
			}
		}
		.buttonStyle(.plain)
	}
}

extension AnnualOverview {
	var decemberSolsticeSolar: Solar? {
		let year = calendar.component(.year, from: timeMachine.date)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		return Solar(for: decemberSolstice, coordinate: location.coordinate.coordinate)
	}
	
	var juneSolsticeSolar: Solar? {
		let year = calendar.component(.year, from: timeMachine.date)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		return Solar(for: juneSolstice, coordinate: location.coordinate.coordinate)
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
