//
//  NotificationManager.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 08/01/2021.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
  @AppStorage(UDValues.notificationTime.key) var notifTime: TimeInterval = UDValues.notificationTime.value
  static let shared = NotificationManager()
  private let notificationCenter = UNUserNotificationCenter.current()
  
  /**
   Requests notification permissions and enables notifications, or removes pending notifications when toggled off.
   - Parameters:
      - on: Whether notifications should be enabled (true) or disabled (false)
      - bindingTo: Optional binding to reflect the notification permission state. If authorization fails, the binding is updated to `false`.
   */
  func toggleNotifications(on enabled: Bool, bindingTo: Binding<Bool>? = nil) {
    if enabled {
      notificationCenter.requestAuthorization(options: [.alert]) { success, error in
        if success {
          print("Enabled!")
          
          DispatchQueue.main.async {
            if let binding = bindingTo {
              binding.wrappedValue = false
            }
          }
        } else if let error = error {
          print(error.localizedDescription)
          
          DispatchQueue.main.async {
            if let binding = bindingTo {
              binding.wrappedValue = false
            }
          }
        }
      }
    } else {
      notificationCenter.removeAllPendingNotificationRequests()
    }
  }
  
  /**
   Schedules a notification for tomorrow's daylight.
   */
  func scheduleNotification() {
    let now = Date()
    let components = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: notifTime))
    let targetDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    let targetNotificationTime = Calendar.current.date(
      bySettingHour: components.hour ?? 8,
      minute: components.minute ?? 0,
      second: 0,
      of: targetDate
    )!
    
    let solsticeCalculator = SolarCalculator(baseDate: targetDate)
    let content = UNMutableNotificationContent()
    content.title = "Today’s Daylight"
    
    if let components = solsticeCalculator.today?.duration,
       let hour = components.hour,
       let minute = components.minute {
      content.subtitle = "\(hour)hrs and \(minute)mins of daylight today."
    } else {
      content.subtitle = "Open Solstice to see the day’s daylight."
    }
    
    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: now.distance(to: targetNotificationTime),
      repeats: false
    )
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
  }
}
