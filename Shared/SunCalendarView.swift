//
//  SunCalendarView.swift
//  Solstice
//
//  Created by Daniel Eden on 13/01/2021.
//

import SwiftUI

struct SunCalendarView: View {
  #if !os(watchOS)
  @Environment(\.horizontalSizeClass) var sizeClass
  #endif
  @ObservedObject var solarCalculator = SolarCalculator.shared
  var daylightArray: [Daylight] = []
  @ScaledMetric var barHeight = 100
  @ScaledMetric var captionSize = isWatch ? 8 : 14
  
  var currentMonth: Int {
    let month = Calendar.current.component(.month, from: solarCalculator.baseDate)
    return month - 1
  }
  
  init() {
    self.daylightArray = self.calculateMonthlyDaylight()
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Daily Daylight Per Month")
          .font(.subheadline)
        Text("Based on the hours of daylight on the 15th day of each month this year")
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
              Text("\(self.hoursOfDaylightForMonth(month))")
              Color.accentColor
                .saturation(daylightArray.firstIndex(of: month) == currentMonth ? 1.0 : 0.0)
                .opacity(daylightArray.firstIndex(of: month) == currentMonth ? 1.0 : 0.5)
                .frame(height: self.calculateDaylightForMonth(month) * barHeight)
                .cornerRadius(4)
              
              #if !os(watchOS)
              Text("\(self.monthAbbreviationFromInt(index, veryShort: sizeClass != .regular))")
                .foregroundColor(.secondary)
              #else
              Text("\(self.monthAbbreviationFromInt(index))")
                .foregroundColor(.secondary)
              #endif
            }.id(month)
          }
        }
      }
      .font(.system(size: captionSize).weight(isWatch ? .semibold : .regular))
      .padding(.bottom)
    }
  }
  
  func calculateMonthlyDaylight() -> [Daylight] {
    let todayComponents = Calendar.current.dateComponents([.year], from: solarCalculator.baseDate)
    var monthsOfDaylight: [Daylight] = []
    let components = DateComponents(
      year: todayComponents.year,
      month: 1,
      day: 15,
      hour: 0,
      minute: 0,
      second: 0
    )
    
    var date = Calendar.current.date(from: components)!
    let calculator = SolarCalculator()
    
    for _ in 1...12 {
      calculator.baseDate = date
      
      monthsOfDaylight.append(calculator.today)
      
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
  
  func monthAbbreviationFromInt(_ month: Int, veryShort: Bool = true) -> String {
    let ma = veryShort ? Calendar.current.veryShortMonthSymbols : Calendar.current.shortMonthSymbols
    return ma[month]
  }
}

struct SunCalendarView_Previews: PreviewProvider {
    static var previews: some View {
      SunCalendarView()
    }
}
