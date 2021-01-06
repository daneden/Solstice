//
//  SolarCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 05/01/2021.
//

import Foundation
import Combine
import CoreLocation

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
    
    return (
      minutes: minutes - otherMinutes,
      seconds: seconds - otherSeconds
    )
  }
}

struct SolarCalculator {
  private let locationManager = LocationManager.shared
  private var coords: CLLocationCoordinate2D? {
    guard let coords =
          locationManager.location?.coordinate,
          CLLocationCoordinate2DIsValid(coords) else { return nil }
    return coords
  }
  
  private var todaysDate: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
  }
  
  var prevSolstice: Date? {
    let components = Calendar.current.dateComponents([.month, .year], from: todaysDate)
    if let month = components.month, month >= 6 {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 6, day: 22))
    } else {
      return Calendar.current.date(from: DateComponents(year: (components.year ?? 0) - 1, month: 12, day: 22))
    }
  }
  
  var nextSolstice: Date? {
    let components = Calendar.current.dateComponents([.month, .year], from: todaysDate)
    if let month = components.month, month >= 12 {
      return Calendar.current.date(from: DateComponents(year: (components.year ?? 0) + 1, month: 6, day: 22))
    } else if let month = components.month, month >= 6 {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 12, day: 22))
    } else {
      return Calendar.current.date(from: DateComponents(year: components.year, month: 6, day: 22))
    }
  }
  
  var prevSolsticeDaylight: Daylight? {
    guard let coords = coords else { return nil }
    guard let solar = Solar(for: prevSolstice!, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var today: Daylight? {
    guard let coords = coords else { return nil }
    guard let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) else { return nil }
    guard let solar = Solar(for: date, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var yesterday: Daylight? {
    guard let coords = coords else { return nil }
    guard let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) else { return nil }
    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return nil }
    guard let solar = Solar(for: yesterday, coordinate: coords) else { return nil }
    
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
    return String("\(abs(minutes)) min\(abs(minutes) > 1 || minutes == 0 ? "s" : "") and \(abs(seconds)) sec\(abs(seconds) > 1 || seconds == 0 ? "s" : "")")
  }
}
