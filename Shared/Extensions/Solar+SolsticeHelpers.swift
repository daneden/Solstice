//
//  Solar+SolsticeHelpers.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 28/12/2021.
//

import Foundation
import Solar
import CoreLocation

extension Solar {
  var timezone: TimeZone {
    LocationManager.shared.placemark?.timeZone ?? .autoupdatingCurrent
  }
  
  var location: CLLocation {
    CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
  var duration: TimeInterval {
    if let sunrise = sunrise, let sunset = sunset {
      return sunrise.distance(to: sunset)
    } else {
      return 0
    }
  }
  
  var nextSolarEvent: SolarEvent {
    if sunrise!.isInFuture {
      return .sunrise(at: sunrise!)
    } else if sunrise!.isInPast && sunset!.isInFuture {
      return .sunset(at: sunset!)
    } else {
      let tomorrow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: date)!
      return .sunrise(at: Solar(for: tomorrow, coordinate: coordinate)!.sunrise!)
    }
  }
  
  func difference(from: Solar) -> TimeInterval {
    return self.duration - from.duration
  }
  
  var begins: Date {
    sunrise!.applyingTimezoneOffset(timezone: timezone)
  }
  
  var ends: Date {
    sunset!.applyingTimezoneOffset(timezone: timezone)
  }
  
  var peak: Date? {
    let interval = ends.timeIntervalSince(begins)
    let peak = begins.advanced(by: interval / 2)
    
    return peak
  }
}

extension Solar: Hashable {
  public static func == (lhs: Solar, rhs: Solar) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(date.hashValue ^ coordinate.longitude.hashValue ^ coordinate.latitude.hashValue)
  }
}
