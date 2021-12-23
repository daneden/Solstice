//
//  LandingViewGradient.swift
//  Solstice
//
//  Created by Daniel Eden on 23/12/2021.
//

import Foundation
import SwiftUI

struct SkyGradient {
  static let dawn = [
    Color(red: 0.388, green: 0.435, blue: 0.643),
    Color(red: 0.91, green: 0.796, blue: 0.753)
  ]
  
  static let morning = [
    Color(red: 0.11, green: 0.573, blue: 0.824),
    Color(red: 0.949, green: 0.988, blue: 0.996)
  ]
  
  static let noon = [
    Color(red: 0.184, green: 0.502, blue: 0.929),
    Color(red: 0.337, green: 0.8, blue: 0.949)
  ]
  
  static let afternoon = [
    Color(red: 0, green: 0.353, blue: 0.655),
    Color(red: 1, green: 0.992, blue: 0.894)
  ]
  
  static let evening = [
    Color(red: 0.208, green: 0.361, blue: 0.49),
    Color(red: 0.424, green: 0.357, blue: 0.482),
    Color(red: 0.753, green: 0.424, blue: 0.518)
  ]
  
  static let night = [
    Color(red: 0.087, green: 0.176, blue: 0.221),
    Color(red: 0.034, green: 0.146, blue: 0.258)
  ]
  
  static var colors: [[Color]] {
    [dawn, morning, noon, afternoon, evening, night]
  }
  
  static func getCurrentPalette() -> [Color] {
    let timeAsIndex = Int(Double(Calendar.autoupdatingCurrent.component(.hour, from: .now) + 8) / 6) % colors.count
    return colors[timeAsIndex]
  }
}
