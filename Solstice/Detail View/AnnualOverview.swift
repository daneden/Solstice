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
	var location: Location
	
	var body: some View {
		Section {
			if let date = timeMachine.date,
				 let nextSolstice = date.nextSolstice,
				 let prevSolstice = date.previousSolstice,
				 let nextEquinox = date.nextEquinox,
				 let solar = Solar(for: date, coordinate: location.coordinate.coordinate),
				 let nextSolsticeSolar = Solar(for: nextSolstice, coordinate: location.coordinate.coordinate),
				 let previousSolsticeSolar = Solar(for: prevSolstice, coordinate: location.coordinate.coordinate) {
				let daylightDifference = abs(solar.daylightDuration - previousSolsticeSolar.daylightDuration)
				let nextGreaterThanPrevious = nextSolsticeSolar.daylightDuration > previousSolsticeSolar.daylightDuration
				
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
