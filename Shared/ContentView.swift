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
      SundialView()
      
      VStack {
        Spacer()
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
      }
    }.edgesIgnoringSafeArea(.bottom)
  }
  
  var verbiage: String {
    calculator.difference >= 0 ? "more" : "fewer"
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
