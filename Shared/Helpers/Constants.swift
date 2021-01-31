//
//  Constants.swift
//  Solstice
//
//  Created by Daniel Eden on 09/01/2021.
//

import Foundation
import SwiftUI
import CoreLocation

typealias UDValuePair<T> = (key: String, value: T)

let defaultNotificationDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
let solsticeSuiteName = "group.me.daneden.Solstice"
let solsticeUDStore = UserDefaults(suiteName: solsticeSuiteName)

struct UDValues {
  typealias Value = UDValuePair
  
  static let cachedLatitude: Value = ("cachedLatitude", 51.5074)
  static let cachedLongitude: Value = ("cachedLongitude", 0.1278)
  
  // General notification settings
  static let notificationTime: Value = ("notifTime", defaultNotificationDate.timeIntervalSince1970)
  static let notificationsEnabled: Value = ("notifsEnabled", false)
  
  // Notification fragment settings
  static let notificationsIncludeSunTimes: Value = ("notifsIncludeSunTimes", true)
  static let notificationsIncludeDaylightDuration: Value = ("notifsIncludeDaylightDuration", true)
  static let notificationsIncludeDaylightChange: Value = ("notifsIncludeDaylightChange", true)
  static let notificationsIncludeSolsticeCountdown: Value = ("notifsIncludeSolsticeCountdown", false)
  
  // Cached Location Results
  static let locations: Value<[Location]> = ("locations", [])
}

let stiffSpringAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3)
let easingSpringAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 1)
