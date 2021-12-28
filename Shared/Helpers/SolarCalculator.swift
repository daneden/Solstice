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
  
  func date() -> Date {
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
  
  var locationManager: LocationManager
  
  var latitude: Double { locationManager.latitude }
  var longitude: Double { locationManager.longitude }
  
  @Published var dateOffset = 0.0
  
  var timezone: TimeZone {
    locationManager.placemark?.timeZone ?? TimeZone.current
  }
  
  @Published var baseDate: Date
  
  var date: Date {
    var offset = DateComponents()
    offset.day = Int(dateOffset)
    
    let date = Date.now
    
    return applyTimezoneOffset(to: calendar.date(byAdding: offset, to: date)!)
  }
  
  init(baseDate: Date = .now, locationManager: LocationManager = LocationManager()) {
    self.baseDate = baseDate
    self.locationManager = locationManager
    super.init()
  }
  
  private func applyTimezoneOffset(to date: Date) -> Date {
    let currentTimezone = TimeZone.current.secondsFromGMT()
    let offsetTimezone = timezone.secondsFromGMT()
    let offsetAmount = currentTimezone < offsetTimezone
      ? max(currentTimezone, offsetTimezone) - min(currentTimezone, offsetTimezone)
      : min(currentTimezone, offsetTimezone) - max(currentTimezone, offsetTimezone)

    let components = DateComponents(second: offsetAmount)
    return calendar.date(byAdding: components, to: date)!
  }
  
  private var baseDateAtNoon: Date {
    calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
  }
  
  private var coords: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  func getNextSolarEvent() -> SolarEvent {
    return today.nextSolarEvent
  }
  
  var prevSolstice: Date {
    let index = Date.solstices.firstIndex(where: { $0 > date })!
    return Date.solstices[index - 1]
  }
  
  var nextSolstice: Date {
    Date.solstices.first(where: { $0 > date }) ?? .now
  }
  
  var prevSolsticeDaylight: Solar {
    return Solar(for: prevSolstice, coordinate: coords)!
  }
  
  var today: Solar {
    Solar(for: baseDateAtNoon, coordinate: coords)!
  }
  
  var yesterday: Solar {
    let yesterday = calendar.date(byAdding: .day, value: -1, to: baseDateAtNoon)!
    return Solar(for: yesterday, coordinate: coords)!
  }
  
  var tomorrow: Solar {
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: baseDateAtNoon)!
    return Solar(for: tomorrow, coordinate: coords)!
  }
  
  var differenceString: String {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .medium
    formatter.formattingContext = .middleOfSentence
    
    let yesterday = date.isToday ? yesterday : Solar(for: .now, coordinate: coords)!
    var string = today.difference(from: yesterday).localizedString
    
    if today.difference(from: yesterday) >= 0 {
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
    
    string += " daylight \(decimalRange == nil ? "" : "on ")\(baseDateString) than \(formatter.string(from: yesterday.sunrise!))."
    
    return string
  }
}
