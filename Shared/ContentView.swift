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
  @EnvironmentObject var locationManager: LocationManager
  @ObservedObject var calculator = SolarCalculator.shared
  @State var selectedDate = Date()
  @State var dateOffset = 0.0
  @State var settingsVisible = false
  @State var timeTravelVisible = false
  
  var body: some View {
    ZStack(alignment: .top) {
      TabView {
        Group {
          VStack {
            Spacer()
            SolarTimeMachine(
              dateOffset: $dateOffset,
              selectedDate: $selectedDate
            )
            Spacer()

            SolsticeOverview()
              .padding()
          }
        }
        .padding(.bottom)
        .padding(.bottom)
        
        Group {
          VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
              Filler()
              Text("The next solstice is \(nextSolsticeDistance).")
              Text("\(prevSolsticeDifference)")
            }
            .font(.title)
            
            Spacer()
            SunCalendarView()
          }
        }
        .padding()
        .padding(.bottom)
        .padding(.bottom)
      }
      .tabViewStyle(PageTabViewStyle())
      .indexViewStyle(PageIndexViewStyle.init(backgroundDisplayMode: .always))
      
      
      HStack {
        Spacer()
        Button(action: { settingsVisible.toggle() }) {
          Label("Settings", systemImage: "gearshape")
            .labelStyle(IconOnlyLabelStyle())
            .foregroundColor(.secondary)
            .padding(6)
            .background(VisualEffectView.SystemThinMaterial())
            .cornerRadius(8)
            .padding(12)
        }
      }.padding().padding(-12)
    }
    .accentColor(.systemTeal)
    .sheet(isPresented: $settingsVisible) {
      SettingsView()
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
