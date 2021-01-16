//
//  TimeInterval.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import Foundation

enum TimeStringAccuracy {
  case hours, minutes, seconds, milliseconds
}

extension TimeInterval {
  func toTimeString(accuracy: TimeStringAccuracy = .minutes) -> String {
    let ti = Int(self)

    let ms = Int((self) * 1000)

    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    
    switch accuracy {
    case .hours:
      return String(format: "%0.2d", hours)
    case .minutes:
      return String(format: "%0.2d:%0.2d", hours, minutes)
    case .seconds:
      return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    default:
      return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }
  }
  
  var colloquialTimeString: String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .short
    formatter.allowedUnits = [.hour, .minute, .second]
    let string = formatter.string(from: abs(self)) ?? ""
    
    return string
  }
  
  static func fromDelimitedString(_ string: String) -> TimeInterval {
    let components = string.split(separator: ":").map { Double($0) ?? 0 }
    switch components.count {
    case 1:
      return TimeInterval(components[0] * 60 * 60)
    case 2:
      return TimeInterval(
        (components[0] * 60 * 60) +
        (components[1] * 60)
      )
    case 3:
      return TimeInterval(
        (components[0] * 60 * 60) +
        (components[1] * 60) +
        (components[2])
      )
    case 4:
      return TimeInterval(
        (components[0] * 60 * 60) +
        (components[1] * 60) +
        (components[2]) +
        (components[3] / 60)
      )
    default:
      return 0
    }
  }
}
