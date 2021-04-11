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
  
  var body: some View {
    ZStack(alignment: .top) {
      ScrollView {
        Group {
          VStack {
            Spacer(minLength: 64)
            SolarTimeMachine(
              dateOffset: $dateOffset,
              selectedDate: $selectedDate
            )
            Spacer()
            
            SolsticeOverview(activeSheet: $activeSheet)
          }
          
          Divider()
          
          VStack(alignment: .leading, spacing: 12) {
            Label("The next solstice is \(nextSolsticeDistance).\n\(prevSolsticeDifference)", systemImage: "calendar")
            
            Divider()
            
            SunCalendarView()
          }
        }
        .padding()
      }
      
      LinearGradient(gradient: .init(colors: [Color.systemBackground.opacity(0.95), Color.systemBackground.opacity(0.1)]), startPoint: .center, endPoint: .bottom)
        .frame(height: 88).edgesIgnoringSafeArea(.top)
      
      HStack {
        Spacer()
        Button(action: { self.activeSheet = .settings }) {
          Label("Settings", systemImage: "gearshape")
            .labelStyle(IconOnlyLabelStyle())
        }
        .buttonStyle(SecondaryButtonStyle())
      }.padding()
    }
    .accentColor(.systemTeal)
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
