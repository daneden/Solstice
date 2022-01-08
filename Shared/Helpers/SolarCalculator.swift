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
import Solar
import OSLog

enum SolarEvent {
  case sunrise(at: Date), sunset(at: Date)
  
  var description: String {
    switch self {
    case .sunrise(_):
      return "sunrise"
    case .sunset(_):
      return "sunset"
    }
  }
  
  var imageName: String { description }
  
  var date: Date {
    switch self {
    case .sunrise(let at):
      return at
    case .sunset(let at):
      return at
    }
  }
}

class SolarCalculator: NSObject, ObservableObject {
  private let calendar = Calendar.autoupdatingCurrent
  
  @Published var locationManager: LocationManager
  @Published var dateOffset = 0.0
  @Published var baseDate: Date
  
  var timezone: TimeZone {
    locationManager.placemark?.timeZone ?? TimeZone.current
  }
  
  var date: Date {
    var offset = DateComponents()
    offset.day = Int(dateOffset)
    
    let date = Date.now
    
    return calendar.date(byAdding: offset, to: date)!.applyingTimezoneOffset(timezone: timezone)
  }
  
  init(baseDate: Date = .now, locationManager: LocationManager = LocationManager.shared) {
    self.baseDate = baseDate
    self.locationManager = locationManager
  }
  
  private var latitude: Double { locationManager.latitude }
  private var longitude: Double { locationManager.longitude }
  private var coords: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  var dateAtNoon: Date {
    calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
  }
  
  var prevSolstice: Date {
    let index = Date.solstices.firstIndex(where: { $0 > date })!
    return Date.solstices[index - 1]
  }
  
  var nextSolstice: Date {
    Date.solstices.first(where: { $0 > date }) ?? .now
  }
  
  var prevSolsticeDaylight: Solar {
    Solar(for: prevSolstice, coordinate: coords)!
  }
  
  var today: Solar {
    Solar(for: date, coordinate: coords)!
  }
  
  var yesterday: Solar {
    let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
    return Solar(for: yesterday, coordinate: coords)!
  }
  
  var tomorrow: Solar {
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
    return Solar(for: tomorrow, coordinate: coords)!
  }
  
  var differenceString: String {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .medium
    formatter.formattingContext = .middleOfSentence
    
    let comparator = dateAtNoon.isToday ? yesterday : Solar(for: .now.applyingTimezoneOffset(timezone: timezone), coordinate: coords)!
    var string = today.difference(from: comparator).localizedString
    
    if today.difference(from: comparator) >= 0 {
      string += " more"
    } else {
      string += " less"
    }
    
    // Check if the base date formatted as a string contains numbers.
    // If it does, this means it's presented as an absolute date, and should
    // be rendered as “on {date}”; if not, it’s presented as a relative date,
    // and should be presented as “{yesterday/today/tomorrow}”
    let baseDateString = formatter.string(from: date)
    let decimalCharacters = CharacterSet.decimalDigits
    let decimalRange = baseDateString.rangeOfCharacter(from: decimalCharacters)
    
    let comparatorDate = comparator.date
    let comparatorDateString = formatter.string(from: comparatorDate)
    
    string += " daylight \(decimalRange == nil ? "" : "on ")\(baseDateString) than \(comparatorDateString)."
    
    return string
  }
}

// MARK: Convenience variables
extension SolarCalculator {
  var isDaytime: Bool {
    today.begins.isInPast && today.ends.isInFuture
  }
  
  var nextSunEvent: SolarEvent {
    if isDaytime {
      return .sunset(at: today.ends)
    } else if today.begins.isInFuture {
      return .sunrise(at: today.begins)
    } else {
      return .sunrise(at: tomorrow.begins)
    }
  }
}
