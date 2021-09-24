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
            SundialView(waveSize: geom.size.height * 0.12)
              .frame(maxWidth: .infinity, idealHeight: geom.size.height * 0.12 * 2.5)
              .padding(.top)
            
            Text("\(calculator.differenceString) daylight today than yesterday.")
              .lineLimit(4)
              .font(.system(.title, design: .rounded).weight(.medium))
              .padding(.vertical)
          }
          
          SolsticeOverview(activeSheet: $activeSheet)
          
          DisclosureGroup(
            isExpanded: $isPickingDate,
            content: {
              Slider(value: $dateOffset, in: -182...182, step: 1,
                     minimumValueLabel: Text("Past").font(.caption),
                     maximumValueLabel: Text("Future").font(.caption)) {
                Text("Chosen date: \(selectedDate, style: .date)")
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
                Label("\(selectedDate, style: .date)", systemImage: "calendar.badge.clock")
                Spacer()
              }
              .frame(maxWidth: .infinity)
              .contentShape(Rectangle())
              .onTapGesture {
                withAnimation { isPickingDate.toggle() }
              }
            }
          )
          
          Label("The next solstice is \(nextSolsticeDistance).\n\(prevSolsticeDifference)", systemImage: "calendar")
            .padding(.vertical, 8)
          
          SunCalendarView()
            .padding(.vertical, 8)
        }
        .listStyle(.plain)
        .toolbar {
          Button(action: { self.activeSheet = .settings }) {
            Label("Settings", systemImage: "gearshape")
          }
        }
        .navigationTitle("Solstice")
      }
      .accentColor(.accentColor)
      .sheet(item: $activeSheet) { item in
        switch item {
        case .settings:
          SettingsView()
        case .location:
          LocationPickerView()
        }
      }
      .onChange(of: dateOffset) { value in
        self.selectedDate = Calendar.current.date(byAdding: .day, value: Int(value), to: Date())!
        self.calculator.dateOffset = value
      }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        if dateOffset == 0 { selectedDate = Date() }
      }
    }
  }
  
  var prevSolsticeDifference: String {
    let prevSolsticeDaylight = calculator.prevSolsticeDaylight
    let today = calculator.today
    let difference = today.difference(from: prevSolsticeDaylight)
    
    let differenceString = difference.colloquialTimeString
    let differenceComparator = difference >= 0 ? "more" : "less"
    return "\(differenceString) \(differenceComparator) daylight today than at the previous solstice."
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
