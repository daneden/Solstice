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
  
  func toColloquialTimeString() -> String {
    let ti = abs(Int(self))

    let ms = abs(Int((self) * 1000))

    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    
    var result: [String] = []
    
    if hours > 0 {
      result.append("\(hours) hrs")
    }
    
    if minutes > 0 {
      result.append("\(minutes) mins")
    }
    
    if seconds > 0 {
      result.append("\(seconds) secs")
    }
    
    switch result.count {
    case 1:
      return result[0]
    case 2:
      return "\(result[0]) and \(result[1])"
    case 3:
      return "\(result[0]), \(result[1]), and \(result[2])"
    default:
      return "0 minutes and 0 seconds"
    }
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
