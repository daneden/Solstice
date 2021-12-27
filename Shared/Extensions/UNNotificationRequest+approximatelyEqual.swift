//
//  UNNotificationRequest+approximatelyEqual.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 27/12/2021.
//

import Foundation
import UserNotifications

extension UNNotificationRequest {
  func isApproximatelyEqual(to otherRequest: UNNotificationRequest) -> Bool {
    guard let selfTrigger = self.trigger as? UNCalendarNotificationTrigger,
          let otherTrigger = otherRequest.trigger as? UNCalendarNotificationTrigger else {
            return false
          }
    
    return (
      self.identifier == otherRequest.identifier &&
      self.content.title == otherRequest.content.title &&
      self.content.body == otherRequest.content.body &&
      selfTrigger.nextTriggerDate() == otherTrigger.nextTriggerDate()
    )
  }
}
