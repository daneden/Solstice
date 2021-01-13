//
//  SolarCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 05/01/2021.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

typealias DaylightTime = (minutes: Int, seconds: Int)

struct Daylight: Hashable {
  var begins: Date
  var ends: Date
  
  var duration: TimeInterval {
    begins.distance(to: ends)
  }
  
  func difference(from: Daylight) -> TimeInterval {
    return self.duration - from.duration
  }
  
  var peak: Date? {
    let interval = ends.timeIntervalSince(begins)
    let peak = begins.advanced(by: interval / 2)
    
    return peak
  }
}

struct SolarCalculator {
  @AppStorage(UDValues.cachedLatitude.key, store: solsticeUDStore)
  var latitude: Double = UDValues.cachedLatitude.value
  
  @AppStorage(UDValues.cachedLongitude.key, store: solsticeUDStore)
  var longitude: Double = UDValues.cachedLongitude.value
  
  var baseDate = Date()
  
  private var baseDateAtNoon: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!
  }
  
  private var todaysDate: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!
  }
  
  private let locationManager = LocationManager.shared
  private var coords: CLLocationCoordinate2D {
    if let coords =
          locationManager.location?.coordinate,
       CLLocationCoordinate2DIsValid(coords) {
      return coords
    } else {
      return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
  }
  
  var prevSolstice: Date? {
    let components = Calendar.current.dateComponents([.month, .day, .year], from: todaysDate)
    if let month = components.month, let day = components.day, month >= 6 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 6, day: 22))
    } else {
      return Calendar.current.date(from: DateComponents(year: (components.year ?? 0) - 1, month: 12, day: 22))
    }
  }
  
  var nextSolstice: Date {
    let components = Calendar.current.dateComponents([.month, .day, .year], from: todaysDate)
    if let month = components.month, let day = components.day, month >= 12 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: (components.year ?? 0) + 1, month: 6, day: 22))!
    } else if let month = components.month, let day = components.day, month >= 6 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 12, day: 22))!
    } else {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 6, day: 22))!
    }
  }
  
  var prevSolsticeDaylight: Daylight? {
    guard let prevSolstice = prevSolstice else { return nil }
    guard let solar = Solar(for: prevSolstice, coordinate: coords) else { return nil }
    
    if let sunrise = solar.sunrise, let sunset = solar.sunset {
      return Daylight(begins: sunrise, ends: sunset)
    } else {
      return nil
    }
  }
  
  var today: Daylight? {
    guard let solar = Solar(for: baseDateAtNoon, coordinate: coords) else { return nil }
    
    if let sunrise = solar.sunrise, let sunset = solar.sunset {
      return Daylight(begins: sunrise, ends: sunset)
    } else {
      return nil
    }
  }
  
  var yesterday: Daylight? {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: baseDateAtNoon)!
    guard let solar = Solar(for: yesterday, coordinate: coords) else { return nil }
    
    if let sunrise = solar.sunrise, let sunset = solar.sunset {
      return Daylight(begins: sunrise, ends: sunset)
    } else {
      return nil
    }
  }
  
  var tomorrow: Daylight? {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: baseDateAtNoon)!
    guard let solar = Solar(for: tomorrow, coordinate: coords) else { return nil }
    
    if let sunrise = solar.sunrise, let sunset = solar.sunset {
      return Daylight(begins: sunrise, ends: sunset)
    } else {
      return nil
    }
  }
  
  var differenceString: String {
    guard let today = today else { return "The same" }
    guard let yesterday = yesterday else { return "The same" }
    var string = today.difference(from: yesterday).toColloquialTimeString()
    
    if today.difference(from: yesterday) >= 0 {
      string += " more"
    } else {
      string += " less"
    }
    
    return string
  }
  
  var monthlyDaylight: [Daylight] {
    let todayComponents = Calendar.current.dateComponents([.year], from: baseDate)
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
      let daylight = solarCalculator.today
      
      if let daylight = daylight {
        monthsOfDaylight.append(daylight)
      }
      
      date = Calendar.current.date(byAdding: .month, value: 1, to: date)!
    }
    
    return monthsOfDaylight
  }
}
