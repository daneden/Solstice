//
//  SunCalendarView.swift
//  Solstice
//
//  Created by Daniel Eden on 13/01/2021.
//

import SwiftUI
import Charts
import Solar

extension Solar: Identifiable {
  public var id: Int {
    date.hashValue + location.hashValue
  }
}

struct SunCalendarView: View {
  @EnvironmentObject var solarCalculator: SolarCalculator
  @EnvironmentObject var locationManager: LocationManager
  
  @State var daylightArray: [Solar] = []
  
  var currentMonth: Int {
    let month = Calendar.current.component(.month, from: solarCalculator.date)
    return month - 1
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Daily Daylight Per Month").font(.headline)
      Text("Based on the hours of daylight on the 15th day of each month this year")
      
      Chart(daylightArray) { daylight in
        BarMark(
          x: .value("Month", daylight.date, unit: .month),
          y: .value("Hours of Daylight", daylight.duration / 60 / 60)
        )
      }
      .animation(.default, value: daylightArray)
      .frame(minHeight: 128)
    }
    .padding(.vertical, 8)
    .onAppear {
      daylightArray = self.calculateMonthlyDaylight()
    }.onChange(of: locationManager.location) { _ in
      daylightArray = self.calculateMonthlyDaylight()
    }
  }
  
  func calculateMonthlyDaylight() -> [Solar] {
    let todayComponents = Calendar.current.dateComponents([.year], from: solarCalculator.date)
    var monthsOfDaylight: [Solar] = []
    
    for month in 1...12 {
      let components = DateComponents(
        year: todayComponents.year,
        month: month,
        day: 15,
        hour: 12,
        minute: 0,
        second: 0
      )
      var date = Calendar.current.date(from: components)!
      
      monthsOfDaylight.append(Solar(for: date, coordinate: locationManager.location!.coordinate)!)
      date = Calendar.current.date(byAdding: .month, value: 1, to: date)!
    }
    
    return monthsOfDaylight
  }
  
  func calculateDaylightForMonth(_ month: Solar) -> CGFloat {
    let longest = daylightArray.reduce(1.0) { (record, currentDaylight) -> TimeInterval in
      currentDaylight.duration > record ? currentDaylight.duration : record
    }
    
    let current = month.duration
    
    return current == longest ? 1.0 : CGFloat(current / longest)
  }
  
  var durationFormatter: DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour]
    
    return formatter
  }
}

struct SunCalendarView_Previews: PreviewProvider {
    static var previews: some View {
      SunCalendarView()
        .padding()
        .environmentObject(SolarCalculator())
        .environmentObject(LocationManager.shared)
    }
}
