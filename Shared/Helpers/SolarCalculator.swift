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

struct Daylight {
  var begins: Date?
  var ends: Date?
  var duration: DateComponents? {
    if let begins = begins, let ends = ends {
      return Calendar.current.dateComponents([.hour, .minute, .second], from: begins, to: ends)
    } else {
      return nil
    }
  }
  
  func difference(from: Daylight) -> DaylightTime {
    let minutes = duration?.minute ?? 0
    let seconds = duration?.second ?? 0
    
    let otherMinutes = from.duration?.minute ?? 0
    let otherSeconds = from.duration?.second ?? 0
    
    var calculatedMinutes = minutes - otherMinutes
    var calculatedSeconds = seconds - otherSeconds
    
    // Sometimes the difference is returned as e.g. 1min and -7sec
    // so in those cases, we'll make up the difference
    if calculatedMinutes > 0 && calculatedSeconds < 0 {
      calculatedMinutes -= 1
      calculatedSeconds += 60
    }
    
    return (
      minutes: calculatedMinutes,
      seconds: calculatedSeconds
    )
  }
  
  var peak: Date? {
    guard let interval = ends?.timeIntervalSince(begins ?? Date()) else {return nil }
    let peak = begins?.advanced(by: interval / 2)
    
    return peak
  }
}

struct SolarCalculator {
  @AppStorage(UDValues.cachedLatitude.key) var latitude: Double = UDValues.cachedLatitude.value
  @AppStorage(UDValues.cachedLongitude.key) var longitude: Double = UDValues.cachedLongitude.value
  
  var baseDate = Date()
  
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
  
  private var todaysDate: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!
  }
  
  var prevSolstice: Date? {
    let components = Calendar.current.dateComponents([.month, .day, .year], from: todaysDate)
    if let month = components.month, let day = components.day, month >= 6 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 6, day: 22))
    } else {
      return Calendar.current.date(from: DateComponents(year: (components.year ?? 0) - 1, month: 12, day: 22))
    }
  }
  
  var nextSolstice: Date? {
    let components = Calendar.current.dateComponents([.month, .day, .year], from: todaysDate)
    if let month = components.month, let day = components.day, month >= 12 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: (components.year ?? 0) + 1, month: 6, day: 22))
    } else if let month = components.month, let day = components.day, month >= 6 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 12, day: 22))
    } else {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 6, day: 22))
    }
  }
  
  var prevSolsticeDaylight: Daylight? {
    guard let prevSolstice = prevSolstice else { return nil }
    guard let solar = Solar(for: prevSolstice, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var today: Daylight? {
    guard let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate) else { return nil }
    guard let solar = Solar(for: date, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var yesterday: Daylight? {
    guard let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate) else { return nil }
    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return nil }
    guard let solar = Solar(for: yesterday, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var tomorrow: Daylight? {
    guard let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate) else { return nil }
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return nil }
    guard let solar = Solar(for: tomorrow, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var difference: DaylightTime {
    guard let today = today, let yesterday = yesterday else {
      return (minutes: 0, seconds: 0)
    }
    
    return today.difference(from: yesterday)
  }
  
  var differenceString: String {
    let (minutes, seconds) = difference
    return String("\(abs(minutes)) min\(abs(minutes) > 1 || minutes == 0 ? "s" : ""), \(abs(seconds)) sec\(abs(seconds) > 1 || seconds == 0 ? "s" : "")")
  }
}
