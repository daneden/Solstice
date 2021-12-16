//
//  Constants.swift
//  Solstice
//
//  Created by Daniel Eden on 09/01/2021.
//

import Foundation
import SwiftUI
import CoreLocation

enum SADPreference: String, CaseIterable, RawRepresentable {
  case none = "No change"
  case removeDifference = "Remove daylight gain/loss"
  case suppressNotifications = "Suppress notifications altogether"
}

enum ScheduleType: String, RawRepresentable {
  case specificTime = "At a specific time"
  case relativeTime = "Relative to sunrise/sunset"
  
  enum Relativity: String, RawRepresentable {
    case before, after
  }
  
  enum Relation: String, RawRepresentable {
    case sunrise, sunset
  }
}

let defaultNotificationDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
let solsticeSuiteName = "group.me.daneden.Solstice"
let solsticeUDStore = UserDefaults(suiteName: solsticeSuiteName)

let isWatch = TARGET_OS_WATCH == 1

struct NotificationSettings: Codable {
  /// The type of notification schedule; either a specific time (specified in `notificationDate`) or relative to sunrise/sunset
  var scheduleType: ScheduleType = .specificTime
  
  /// The date/time for notification scheduling. Only the time will be used.
  var notificationDate: Date = defaultNotificationDate
  
  /// Whether relative notifications are sent before or after the chosen event
  var relativity: ScheduleType.Relativity = .before
  
  /// Which solar event notifications are sent relative to
  var relation: ScheduleType.Relation = .sunrise
  
  /// The offset in seconds between the notification and the chosen solar event
  var relativeOffset = TimeInterval(0)
}

extension NotificationSettings: RawRepresentable {
  init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(NotificationSettings.self, from: data)
    else {
      return nil
    }
    self = result
  }
  
  var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }
    return result
  }
}

// MARK: User Defaults
typealias UDValuePair<T> = (key: String, value: T)

struct UDValues {
  typealias Value = UDValuePair
  
  // MARK: Location Caching
  static let cachedLatitude: Value = ("cachedLatitude", 51.5074)
  static let cachedLongitude: Value = ("cachedLongitude", 0.1278)
  
  
  // MARK: Notifications
  /// The user preference for whether notifications are enabled
  static let notificationsEnabled: Value = ("notifsEnabled", false)
  
  /// The user preference for whether notifications include sunrise/sunset times
  static let notificationsIncludeSunTimes: Value = ("notifsIncludeSunTimes", true)
  
  /// The user preference for whether notifications include the daylight duration
  static let notificationsIncludeDaylightDuration: Value = ("notifsIncludeDaylightDuration", true)
  
  /// The user preference for whether notifications include the change in daylight compared to yesterday
  static let notificationsIncludeDaylightChange: Value = ("notifsIncludeDaylightChange", true)
  
  /// The user preference for whether notifications include the time until the next solstice
  static let notificationsIncludeSolsticeCountdown: Value = ("notifsIncludeSolsticeCountdown", false)
  
  /// The user preference for how notifications are altered during periods of lessening daylight
  static let sadPreference: Value<SADPreference> = ("sadPreverence", .none)
  
  // MARK: Scheduling
  /// The user preference for whether notifications are sent at a specific time or at a time relative to sunrise/sunset
  static let notificationSettings: Value<NotificationSettings> = ("scheduleType", NotificationSettings())
  
  /// The user preference for what time notifications are sent at
  static let notificationTime: Value = ("notifTime", defaultNotificationDate.timeIntervalSince1970)
  
  #if !os(watchOS)
  // Cached Location Results
  static let locations: Value<[Location]> = ("locations", [])
  #endif
}

// MARK: Animation Globals
let stiffSpringAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3)
let easingSpringAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 1)


// MARK: In-App Purchase Product IDs
let iapProductIDs = Set([
  "me.daneden.Solstice.iap.tip.small",
  "me.daneden.Solstice.iap.tip.medium",
  "me.daneden.Solstice.iap.tip.large"
])
