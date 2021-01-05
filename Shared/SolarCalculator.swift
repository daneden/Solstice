//
//  SolarCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 05/01/2021.
//

import Foundation
import Combine
import CoreLocation

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
  
  func difference(from: Daylight) -> TimeInterval {
    let minutes = Double(duration?.minute ?? 0) / 60
    let seconds = Double(duration?.second ?? 0)
    
    let otherMinutes = Double(from.duration?.minute ?? 0) / 60
    let otherSeconds = Double(from.duration?.second ?? 0) / 60
    return TimeInterval((minutes + seconds) - (otherMinutes + otherSeconds))
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
  
  var today: Daylight? {
    guard let coords = coords else { return nil }
    guard let solar = Solar(coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var yesterday: Daylight? {
    guard let coords = coords else { return nil }
    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return nil }
    guard let solar = Solar(for: yesterday, coordinate: coords) else { return nil }
    
    return Daylight(begins: solar.sunrise, ends: solar.sunset)
  }
  
  var difference: TimeInterval {
    guard let today = today, let yesterday = yesterday else {
      return 0.0
    }
    
    return today.difference(from: yesterday)
  }
  
  var differenceString: String {
    return String(format: "%.2f", difference)
  }
}

extension Double {
  /// Rounds the double to decimal places value
  func rounded(toPlaces places:Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
}
