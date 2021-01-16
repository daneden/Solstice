//
//  SunCalendarView.swift
//  Solstice
//
//  Created by Daniel Eden on 13/01/2021.
//

import SwiftUI

struct SunCalendarView: View {
  @ObservedObject var solarCalculator: SolarCalculator = SolarCalculator.shared
  var daylightArray: [Daylight] = []
  
  var currentMonth: Int {
    let month = Calendar.current.component(.month, from: solarCalculator.baseDate)
    return month - 1
  }
  
  init(solarCalculator: SolarCalculator) {
    self.solarCalculator = solarCalculator
    self.daylightArray = self.calculateMonthlyDaylight()
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading) {
        Text("Hours of daylight per month")
          .font(.subheadline)
        Text("Based on the hours of daylight on the first day of each month this year")
          .fixedSize(horizontal: false, vertical: true)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      HStack(alignment: .bottom) {
        ForEach(daylightArray, id: \.self) { month in
          if let index = daylightArray.firstIndex(of: month) {
            if index != 0 {
              Spacer()
            }
            
            VStack {
              Text("\(self.hoursOfDaylightForMonth(month))").font(.caption)
              Rectangle()
                .fill(Color.clear)
                .background(
                  daylightArray.firstIndex(of: month) == currentMonth
                    ? AnyView(Color.accentColor)
                    : AnyView(VisualEffectView.SystemInvertedRuleMaterial())
                )
                .frame(width: 12, height: self.calculateDaylightForMonth(month) * 200)
                .cornerRadius(4)
              
              Text("\(self.monthAbbreviationFromInt(index))")
                .font(.caption)
                .foregroundColor(.secondary)
            }.id(month)
          }
        }
      }
      .padding(.bottom)
    }
  }
  
  func calculateMonthlyDaylight() -> [Daylight] {
    let todayComponents = Calendar.current.dateComponents([.year], from: solarCalculator.baseDate
    )
    var monthsOfDaylight: [Daylight] = []
    let components = DateComponents(
      year: todayComponents.year,
      month: 1,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0
    )
    
    var date = Calendar.current.date(from: components)!
    
    for _ in 1...12 {
      let solarCalculator = SolarCalculator(baseDate: date)
      
      monthsOfDaylight.append(solarCalculator.today)
      
      date = Calendar.current.date(byAdding: .month, value: 1, to: date)!
    }
    
    return monthsOfDaylight
  }
  
  func hoursOfDaylightForMonth(_ month: Daylight) -> Int {
    return Int(month.duration / 60 / 60)
  }
  
  func calculateDaylightForMonth(_ month: Daylight) -> CGFloat {
    let longest = daylightArray.reduce(0) { (record, currentDaylight) -> TimeInterval in
      currentDaylight.duration > record ? currentDaylight.duration : record
    }
    
    let current = month.duration
    
    return current == longest ? 1.0 : CGFloat(current / longest)
  }
  
  func monthAbbreviationFromInt(_ month: Int) -> String {
    let ma = Calendar.current.shortMonthSymbols
    return ma[month]
  }
}

struct SunCalendarView_Previews: PreviewProvider {
    static var previews: some View {
      SunCalendarView(solarCalculator: SolarCalculator())
    }
}
