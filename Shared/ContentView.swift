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
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
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
