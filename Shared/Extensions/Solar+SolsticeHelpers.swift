//
//  Solar+SolsticeHelpers.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 28/12/2021.
//

import Foundation
import Solar

extension Solar {
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
    sunrise!
  }
  
  var ends: Date {
    sunset!
  }
  
  var peak: Date? {
    let interval = sunset!.timeIntervalSince(begins)
    let peak = sunrise!.advanced(by: interval / 2)
    
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
