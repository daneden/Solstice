//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import Combine
import CoreLocation

struct ContentView: View {
  @EnvironmentObject private var locationManager: LocationManager
  @EnvironmentObject private var calculator: SolarCalculator
  
  var selectedDate: Date {
    calculator.date
  }
  
  @State var timeTravelVisible = false
  
  var body: some View {
    GeometryReader { geom in
			List {
				VStack(alignment: .leading) {
					SundialView(sunSize: isWatch ? 12 : 24, trackWidth: isWatch ? 2 : 3)
						.padding(.horizontal, -20)
						.frame(maxWidth: .infinity, idealHeight: max(geom.size.height * 0.3, 120))
					
					Text(calculator.differenceString)
						.fixedSize(horizontal: false, vertical: true)
						.font(isWatch ? .body : .title)
						.fontWeight(.medium)
						.padding(.bottom)
				}
				
				SolsticeOverview()
				
				#if !os(watchOS)
				DisclosureGroup {
					Slider(value: $calculator.dateOffset, in: -182...182, step: 1,
								 minimumValueLabel: Text("Past").font(.caption),
								 maximumValueLabel: Text("Future").font(.caption)) {
						HStack {
							Text("Chosen date: \(selectedDate, style: .date)")
							
						}
					}
								 .accentColor(.systemFill)
								 .foregroundColor(.secondary)
					
					Button(action: { calculator.dateOffset = 0 }) {
						HStack {
							Label("Reset", systemImage: "arrow.counterclockwise")
							Spacer()
						}
						.contentShape(Rectangle())
					}.disabled(calculator.dateOffset == 0).buttonStyle(BorderlessButtonStyle())
				} label: {
					Label {
						Text(selectedDate, style: .date)
							.fontWeight(selectedDate.isToday ? .regular : .semibold)
							.capsuleAppearance(on: !selectedDate.isToday)
					} icon: {
						Image(systemName: "calendar.badge.clock")
					}
				}
				#endif
				
				Label("The next solstice is \(nextSolsticeDistance).\n\(prevSolsticeDifference)", systemImage: "calendar")
				
				SunCalendarView()
			}
			.listStyle(.plain)
			.navigationTitle(getPlaceName())
      .accentColor(.accentColor)
    }
  }
  
	func getPlaceName() -> String {
		let sublocality = locationManager.placemark?.subLocality
		let locality = locationManager.placemark?.locality
		
		let builtString = [sublocality, locality]
			.compactMap { $0 }
			.joined(separator: ", ")
		
		return builtString.count == 0 ? "Current Location" : builtString
	}
	
  var prevSolsticeDifference: String {
    let prevSolsticeDaylight = calculator.prevSolsticeDaylight
    let today = calculator.today
    let difference = today.difference(from: prevSolsticeDaylight)
    
    let differenceString = difference.localizedString
    let differenceComparator = difference >= 0 ? "more" : "less"
    let comparedToDate = calculator.baseDate.isToday ? "today" : "on this day"
    return "\(differenceString) \(differenceComparator) daylight \(comparedToDate) than at the previous solstice."
  }
  
  var nextSolsticeDistance: String {
    let formatter = RelativeDateTimeFormatter()
    return formatter.localizedString(for: calculator.nextSolstice, relativeTo: selectedDate)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(SheetPresentationManager())
  }
}
