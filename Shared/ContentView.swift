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
        VStack(alignment: .leading, spacing: 4) {
          Spacer(minLength: geometry.size.height / 2)
          
          if let location = location.placemark?.locality ?? "Current Location" {
            Label(location, systemImage: "location.fill")
              .font(Font.subheadline.bold())
              .foregroundColor(.secondary)
            Spacer()
          }
          
          Text("There are \(calculator.differenceString) \(verbiage) seconds of daylight today than yesterday.")
            .font(Font.system(.largeTitle, design: .rounded).bold())
            .padding(.vertical)
          
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Text("Today").font(.caption)
                Spacer()
              }
              if let ends = calculator.today?.ends,
                 let begins = calculator.today?.begins {
                Label("\(begins, style: .time)", systemImage: "sunrise.fill")
                Label("\(ends, style: .time)", systemImage: "sunset.fill")
              }
            }
            
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Text("Yesterday").font(.caption)
                Spacer()
              }
              if let ends = calculator.yesterday?.ends,
                 let begins = calculator.yesterday?.begins {
                Label("\(begins, style: .time)", systemImage: "sunrise")
                Label("\(ends, style: .time)", systemImage: "sunset")
              }
            }.foregroundColor(.secondary)
          }
          
          Spacer()
          
          if let nextSolstice = calculator.nextSolstice {
            Text("\(nextSolstice, style: .relative) until the next solstice")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding()
        .padding(.bottom)
      }
    }
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
