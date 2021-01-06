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
    ZStack {
      SundialView(currentPosition: daylightProgress)
      
      GeometryReader { geometry in
        VStack(alignment: .leading, spacing: 6) {
          if let location = location.placemark?.locality {
            Label(location, systemImage: "location.fill")
              .font(Font.subheadline.bold())
              .foregroundColor(.secondary)
            Spacer()
          }
          
          if let today = calculator.today?.begins,
             let yesterday = calculator.yesterday?.begins {
            Label("Yesterday: \(yesterday, style: .time)", systemImage: "sunrise")
              .foregroundColor(.tertiaryLabel)
            
            Label("Today: \(today, style: .time)", systemImage: "sunrise.fill")
              .foregroundColor(.secondary)
          }
          
          Text("\(calculator.differenceString) \(verbiage) seconds of daylight today than yesterday.")
            .font(Font.system(.largeTitle, design: .rounded).bold())
            .padding(.vertical)
          
          if let today = calculator.today?.ends,
             let yesterday = calculator.yesterday?.ends {
            Label("Today: \(today, style: .time)", systemImage: "sunset.fill")
              .foregroundColor(.secondary)
            
            Label("Yesterday: \(yesterday, style: .time)", systemImage: "sunset")
              .foregroundColor(.tertiaryLabel)
          }
        }
        .padding()
        .padding(.bottom)
        .padding(.bottom)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        .offset(y: geometry.size.height / 4)
        .frame(width: geometry.size.width, height: geometry.size.height / 2)
      }
    }.edgesIgnoringSafeArea(.bottom)
  }
  
  var verbiage: String {
    calculator.difference >= 0 ? "more" : "fewer"
  }
  
  var daylightProgress: Double {
    let begins = calculator.today?.begins ?? Date()
    let ends = calculator.today?.ends ?? Date()
    let period = begins.distance(to: ends)
    return begins.distance(to: Date()) / period
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
