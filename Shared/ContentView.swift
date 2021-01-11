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
  var calculator = SolarCalculator()
  @State var settingsVisible = false
  
  var body: some View {
    VStack {
      SundialView()
      
      VStack(alignment: .leading, spacing: 4) {
        TabView {
          SolsticeOverview()
            .padding()
          if let nextSolstice = calculator.nextSolstice,
             let prevSolsticeDifference = prevSolsticeDifference {
            VStack {
              VStack(alignment: .leading, spacing: 8) {
                Text("\(nextSolstice, style: .relative) until the next solstice.")
                
                Text(prevSolsticeDifference)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }.font(Font.system(.largeTitle, design: .rounded).bold()).padding()
          }
        }.tabViewStyle(PageTabViewStyle())
      }
    }.toolbar {
      ToolbarItem {
        Button(action: { settingsVisible.toggle() }) {
          Label("Settings", systemImage: "gearshape")
        }
      }
    }.sheet(isPresented: $settingsVisible) {
      SettingsView()
    }
  }
  
  var prevSolsticeDifference: String? {
    guard let prevSolsticeDaylight = calculator.prevSolsticeDaylight else { return nil }
    print(prevSolsticeDaylight)
    guard let today = calculator.today else { return nil }
    var (minutes, seconds) = today.differenceComponents(from: prevSolsticeDaylight)
    let difference = today.difference(from: prevSolsticeDaylight)
    
    var value = "\(abs(minutes)) min\(abs(minutes) > 1 || minutes == 0 ? "s" : ""), \(abs(seconds)) sec\(abs(seconds) > 1 || seconds == 0 ? "s" : "")"
    
    if minutes > 0 && seconds < 0 {
      minutes -= 1
      seconds += 60
    }
    
    if difference >= 0 {
      value += " more "
    } else {
      value += " less "
    }
    
    value += "daylight today than at the previous solstice."
    
    return value
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
