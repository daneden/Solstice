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
    let now = Date()
    return self < now
  }
  
  var isInFuture: Bool { !isInPast }
  
  var isToday: Bool {
    let calendar = Calendar.current
    return calendar.isDateInToday(self)
  }
}

extension Date {
  static var solstices: [Date] {
    let year = Calendar.autoupdatingCurrent.component(.year, from: .now)
    var result: [Date] = []
    
    for currentYear in year-10...year+10 {
      result.append(SolsticeCalculator.juneSolstice(year: currentYear))
      result.append(SolsticeCalculator.decemberSolstice(year: currentYear))
    }
    
    return result
  }
}
