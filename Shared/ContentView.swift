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
  var calculator = SolarCalculator()
  @ObservedObject var location = LocationManager.shared
  
  var body: some View {
    VStack {
      SundialView()
      
      VStack(alignment: .leading, spacing: 4) {
        TabView {
          SolsticeOverview()
          VStack {
            if let nextSolstice = calculator.nextSolstice,
               let prevSolsticeDifference = prevSolsticeDifference {
              VStack(alignment: .leading, spacing: 8) {
                Text("\(nextSolstice, style: .relative) until the next solstice.")
                
                Text(prevSolsticeDifference)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
          }.font(Font.system(.largeTitle, design: .rounded))
        }.tabViewStyle(PageTabViewStyle())
      }
      .padding()
    }
  }
  
  var daylightProgress: Double {
    let begins = Date().startOfDay
    let ends = Date().endOfDay
    let period = begins.distance(to: ends)
    return begins.distance(to: Date()) / period
  }
  
  var daylightOffset: Double {
    let dayBegins = Date().startOfDay
    let dayEnds = Date().endOfDay
    let dayLength = dayBegins.distance(to: dayEnds)
    
    let daylightBegins = calculator.today?.begins ?? dayBegins
    let daylightEnds = calculator.today?.ends ?? dayEnds
    let daylightLength = daylightBegins.distance(to: daylightEnds)
    
    return daylightLength / dayLength
  }
  
  var prevSolsticeDifference: String? {
    guard let prevSolsticeDaylight = calculator.prevSolsticeDaylight else { return nil }
    guard let today = calculator.today else { return nil }
    var (minutes, seconds) = prevSolsticeDaylight.difference(from: today)
    var value = "\(abs(minutes)) min\(abs(minutes) > 1 || minutes == 0 ? "s" : ""), \(abs(seconds)) sec\(abs(seconds) > 1 || seconds == 0 ? "s" : "")"
    
    if minutes > 0 && seconds < 0 {
      minutes -= 1
      seconds += 60
    }
    
    if minutes >= 0 && seconds >= 0 {
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
