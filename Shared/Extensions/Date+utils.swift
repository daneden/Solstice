//
//  Date.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import Foundation

extension Date {
  var startOfDay: Date {
    return Calendar.current.startOfDay(for: self)
  }
  
  var endOfDay: Date {
    var components = DateComponents()
    components.day = 1
    components.second = -1
    return Calendar.current.date(byAdding: components, to: startOfDay)!
  }
  
  var startOfMonth: Date {
    let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
    return Calendar.current.date(from: components)!
  }
  
  var endOfMonth: Date {
    var components = DateComponents()
    components.month = 1
    components.second = -1
    return Calendar.current.date(byAdding: components, to: startOfMonth)!
  }
  
  var isInPast: Bool {
    self < .now
  }
  
  var isInFuture: Bool { !isInPast }
  
  var isToday: Bool {
    let calendar = Calendar.current
    return calendar.isDateInToday(self)
  }
  
  func applyingTimezoneOffset(timezone: TimeZone) -> Date {
    let currentTimezone = TimeZone.current.secondsFromGMT()
    let offsetTimezone = timezone.secondsFromGMT()
    let offsetAmount = currentTimezone < offsetTimezone
    ? max(currentTimezone, offsetTimezone) - min(currentTimezone, offsetTimezone)
    : min(currentTimezone, offsetTimezone) - max(currentTimezone, offsetTimezone)
    
    let components = DateComponents(second: offsetAmount)
    return Calendar.autoupdatingCurrent.date(byAdding: components, to: self)!
  }
}

extension Date {
  static var solstices: [Date] {
    let year = Calendar.autoupdatingCurrent.component(.year, from: .now)
    var result: [Date] = []
    
    for currentYear in year-1...year+1 {
      result.append(SolsticeCalculator.juneSolstice(year: currentYear))
      result.append(SolsticeCalculator.decemberSolstice(year: currentYear))
    }
    
    return result
  }
  
  static func prevSolstice(from date: Date) -> Date {
    let index = Date.solstices.firstIndex(where: { $0 > date })!
    return Date.solstices[index - 1]
  }
  
  static func nextSolstice(from date: Date) -> Date {
    Date.solstices.first(where: { $0 > date }) ?? .now
  }
  
  static var todayAtNoon: Date {
    Calendar.autoupdatingCurrent.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
  }
}
