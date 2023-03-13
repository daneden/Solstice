//
//  AnnualOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar

struct AnnualOverview<Location: AnyLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
	@State var differenceFromPreviousSolstice: TimeInterval?
	
	var location: Location
	
	var month: Int {
		Calendar.autoupdatingCurrent.dateComponents([.month], from: timeMachine.date.nextSolstice).month ?? 6
	}
	
	var nextGreaterThanPrevious: Bool {
		switch month {
		case 6:
			return location.latitude > 0 ? false : true
		case 12:
			return location.latitude > 0 ? true : false
		default:
			return true
		}
	}
	
	var body: some View {
		Section {
			if let date = timeMachine.date,
				 let nextSolstice = timeMachine.date.nextSolstice,
				 let nextEquinox = timeMachine.date.nextEquinox {
				
				VStack(alignment: .leading) {
					AdaptiveLabeledContent {
						if nextSolstice.startOfDay == date.startOfDay {
							Text("Today")
						} else {
							Text(relativeDateFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
						}
					} label: {
						Label("Next Solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
					}
					
					if let differenceFromPreviousSolstice {
						Label {
							Text("\(timeIntervalFormatter.string(from: abs(differenceFromPreviousSolstice)) ?? "") \(nextGreaterThanPrevious ? "more" : "less") daylight on this day compared to the previous solstice")
								.font(.caption)
								.foregroundStyle(.secondary)
						} icon: {
							Color.clear.frame(width: 0, height: 0)
						}
					}
				}
				
				AdaptiveLabeledContent {
					if nextEquinox.startOfDay == date.startOfDay {
						Text("Today")
					} else {
						Text(relativeDateFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
					}
				} label: {
					Label("Next Equinox", systemImage: "circle.and.line.horizontal")
				}
			}
			
			AnnualDaylightChart(location: location)
				.frame(height: chartHeight)
		}
		.task(id: timeMachine.date) {
			if let solar = Solar(for: timeMachine.date, coordinate: location.coordinate.coordinate),
				 let previousSolsticeSolar = Solar(for: solar.date.previousSolstice, coordinate: location.coordinate.coordinate) {
				withAnimation(.interactiveSpring()) {
					differenceFromPreviousSolstice = previousSolsticeSolar.daylightDuration - solar.daylightDuration
				}
			}
		}
	}
}


struct AnnualOverview_Previews: PreviewProvider {
	static var previews: some View {
		Form {
			TimeMachineView()
			AnnualOverview(location: TemporaryLocation.placeholderLocation)
		}
		.environmentObject(TimeMachine())
	}
}
