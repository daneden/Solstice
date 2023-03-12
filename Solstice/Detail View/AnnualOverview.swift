//
//  AnnualOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar

struct AnnualOverview<Location: AnyLocation>: View {
	var solar: Solar
	var location: Location
	
	var body: some View {
		Section {
			if let date = solar.date,
				 let nextSolstice = solar.date.nextSolstice,
				 let prevSolstice = solar.date.previousSolstice,
				 let nextEquinox = solar.date.nextEquinox,
				 let nextSolsticeSolar = Solar(for: nextSolstice, coordinate: solar.coordinate),
				 let previousSolsticeSolar = Solar(for: prevSolstice, coordinate: solar.coordinate) {
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
					
					Label {
						Text("\(timeIntervalFormatter.string(from: daylightDifference) ?? "") \(nextGreaterThanPrevious ? "more" : "less") daylight on this day compared to the previous solstice")
							.font(.caption)
							.foregroundStyle(.secondary)
					} icon: {
						Color.clear.frame(width: 0, height: 0)
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
			AnnualOverview(solar: Solar(coordinate: TemporaryLocation.placeholderLocation.coordinate.coordinate)!, location: TemporaryLocation.placeholderLocation)
		}
	}
}
