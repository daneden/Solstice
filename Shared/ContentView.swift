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
      SundialView(currentPosition: daylightProgress, offset: daylightOffset)
      
      GeometryReader { geometry in
        VStack(alignment: .leading, spacing: 4) {
          Spacer(minLength: geometry.size.height / 2)
          
          if let location = location.placemark?.locality ?? "Current Location" {
            Label(location, systemImage: "location.fill")
              .font(Font.subheadline.bold())
              .foregroundColor(.secondary)
            Spacer(minLength: 0)
          }
          
          Text("\(calculator.differenceString) \(verbiage) daylight today than yesterday.")
            .lineLimit(4)
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
            VStack(alignment: .leading, spacing: 4) {
              Label("\(nextSolstice, style: .relative) until the next solstice", systemImage: "calendar")
              Text(prevSolsticeDifference)
            }
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
    calculator.difference.minutes >= 0 && calculator.difference.seconds >= 0
      ? "more" : "less"
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
  
  var prevSolsticeDifference: String {
    let prevSolsticeDaylight = calculator.prevSolsticeDaylight!
    let (minutes, seconds) = prevSolsticeDaylight.difference(from: calculator.today!)
    var value = "\(abs(minutes)) min\(abs(minutes) > 1 || minutes == 0 ? "s" : "") and \(abs(seconds)) sec\(abs(seconds) > 1 || seconds == 0 ? "s" : "")"
    if minutes > 0 && seconds > 0 {
      value += " more daylight today than at the previous solstice"
    } else {
      value += " less daylight today than at the previous solstice"
    }
    
    return value
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
