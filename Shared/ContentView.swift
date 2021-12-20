//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import Combine
import CoreLocation

enum SheetPresentationState: Identifiable {
  case settings, location
  
  var id: Int {
    hashValue
  }
}

struct ContentView: View {
  @EnvironmentObject var locationManager: LocationManager
  @ObservedObject var calculator = SolarCalculator.shared
  @State var selectedDate = Date()
  @State var dateOffset = 0.0
  @State var settingsVisible = false
  @State var timeTravelVisible = false
  @State var locationPickerVisible = false
  
  @State var activeSheet: SheetPresentationState?
  @State var isPickingDate = false
  
  var body: some View {
    GeometryReader { geom in
      NavigationView {
        List {
          VStack(alignment: .leading) {
            SundialView(sunSize: isWatch ? 12 : 24, trackWidth: isWatch ? 2 : 3)
              .padding(.horizontal, -20)
              .frame(maxWidth: .infinity, idealHeight: max(geom.size.height * 0.3, 120))
            
            Text(calculator.differenceString)
              .lineLimit(4)
              .fixedSize(horizontal: false, vertical: true)
              .font(.system(isWatch ? .body : .title, design: .rounded).weight(.medium))
              .padding(.bottom)
          }
          
          SolsticeOverview(activeSheet: $activeSheet)
          
          #if !os(watchOS)
          DisclosureGroup(
            isExpanded: $isPickingDate,
            content: {
              Slider(value: $dateOffset, in: -182...182, step: 1,
                     minimumValueLabel: Text("Past").font(.caption),
                     maximumValueLabel: Text("Future").font(.caption)) {
                HStack {
                  Text("Chosen date: \(selectedDate, style: .date)")
                  
                }
              }
                     .accentColor(.systemFill)
                     .foregroundColor(.secondary)
              
              Button(action: { withAnimation { dateOffset = 0 }}) {
                HStack {
                  Label("Reset", systemImage: "arrow.counterclockwise")
                  Spacer()
                }
                .contentShape(Rectangle())
              }.disabled(dateOffset == 0).buttonStyle(BorderlessButtonStyle())
            },
            label: {
              HStack {
                Label {
                  Text(selectedDate, style: .date)
                    .fontWeight(selectedDate.isToday ? .regular : .semibold)
                    .capsuleAppearance(on: !selectedDate.isToday)
                } icon: {
                  Image(systemName: "calendar.badge.clock")
                }
                Spacer()
              }
              .frame(maxWidth: .infinity)
              .contentShape(Rectangle())
              .onTapGesture {
                withAnimation { isPickingDate.toggle() }
              }
            }
          )
          #endif
          
          Label("The next solstice is \(nextSolsticeDistance).\n\(prevSolsticeDifference)", systemImage: "calendar")
            .padding(.vertical, 8)
          
          SunCalendarView()
            .padding(.vertical, 8)
        }
        .listStyle(.plain)
        #if !os(watchOS)
        .toolbar {
          Button(action: { self.activeSheet = .settings }) {
            Label("Settings", systemImage: "gearshape")
          }
        }
        #endif
        .navigationTitle("Solstice")
      }
      .accentColor(.accentColor)
      .onChange(of: dateOffset) { value in
        self.selectedDate = Calendar.current.date(byAdding: .day, value: Int(value), to: Date())!
        self.calculator.dateOffset = value
      }
      #if os(iOS)
      .sheet(item: $activeSheet) { item in
        switch item {
        case .settings:
          SettingsView()
        case .location:
          LocationPickerView()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        if dateOffset == 0 { selectedDate = Date() }
      }
      #endif
    }
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
  }
}
