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
  @State var calculator = SolarCalculator.shared
  @State var selectedDate = Date()
  @State var dateOffset = 0.0
  @State var settingsVisible = false
  @State var timeTravelVisible = false
  
  var body: some View {
    ZStack {
      TabView {
        Group {
          VStack {
            Spacer()
            SolarTimeMachine(
              timeTravelVisible: $timeTravelVisible,
              dateOffset: $dateOffset,
              selectedDate: $selectedDate,
              calculator: calculator
            )
            Spacer()

            SolsticeOverview(calculator: calculator)
              .padding()
          }
        }
        .padding(.bottom)
        .padding(.bottom)
        
        Group {
          VStack {
            Spacer()
            SunCalendarView(solarCalculator: calculator)
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
              Filler()
              Text("The next solstice is \(nextSolsticeDistance).")
                .fixedSize(horizontal: false, vertical: true)
              
              if let value = prevSolsticeDifference() {
                Text("\(value)")
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .font(Font.system(.title, design: .rounded).bold())
          }
        }
        .padding()
        .padding(.bottom)
        .padding(.bottom)
      }
      .tabViewStyle(PageTabViewStyle())
      .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
      
      VStack {
        HStack {
          Spacer()
          Button(action: { settingsVisible.toggle() }) {
            Label("Settings", systemImage: "gear")
              .labelStyle(IconOnlyLabelStyle())
          }
          .foregroundColor(.secondary)
          .padding(6)
          .background(VisualEffectView.SystemMaterial())
          .cornerRadius(8)
          
        }.padding()
        Spacer()
      }
    }
    .sheet(isPresented: $settingsVisible) {
      SettingsView()
    }
    .onChange(of: dateOffset) { value in
      DispatchQueue.main.async {
        self.selectedDate = Calendar.current.date(byAdding: .day, value: Int(value), to: Date())!
        self.calculator.baseDate = self.selectedDate
      }
    }
    .onAppear {
      if dateOffset == 0 {
        self.selectedDate = Date()
      }
    }
  }
  
  func prevSolsticeDifference() -> String {
    let prevSolsticeDaylight = calculator.prevSolsticeDaylight
    let today = calculator.today
    let difference = today.difference(from: prevSolsticeDaylight)
    
    let differenceString = difference.colloquialTimeString
    let differenceComparator = difference >= 0 ? "more" : "less"
    let sentence = String(format: "%@ %@ daylight today than at the previous solstice.", differenceString, differenceComparator)
//    let sentence = "\(differenceString) \(differenceComparator) daylight today than at the previous solstice."
    
    return sentence
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
