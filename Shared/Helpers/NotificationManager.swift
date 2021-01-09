//
//  NotificationManager.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 08/01/2021.
//

import Foundation
import UserNotifications
import SwiftUI
import BackgroundTasks

class NotificationManager: ObservableObject {
  @AppStorage(UDValues.notificationTime.key) var notifTime: TimeInterval = UDValues.notificationTime.value
  static let shared = NotificationManager()
  private let notificationCenter = UNUserNotificationCenter.current()
  
  func getPending(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
    notificationCenter.getPendingNotificationRequests(completionHandler: completionHandler)
  }
  
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
          print("Enabled notifications")
          self.scheduleNotification()
          
          DispatchQueue.main.async {
            if let binding = bindingTo {
              binding.wrappedValue = true
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
  
  func adjustSchedule() {
    notificationCenter.removeAllPendingNotificationRequests()
    scheduleNotification()
  }
  
  /**
   Schedules a notification for tomorrow's daylight.
   */
  func scheduleNotification(from task: BGAppRefreshTask? = nil) {
    self.getPending { requests in
      if requests.isEmpty {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: self.notifTime))
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
        
        if let components = solsticeCalculator.today?.durationComponents,
           let hour = components.hour,
           let minute = components.minute {
          content.body = "\(hour)hrs and \(minute)mins of daylight today."
        } else {
          content.body = "Open Solstice to see the day’s daylight."
        }
        
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: Calendar.current.dateComponents([.hour, .minute], from: targetNotificationTime),
          repeats: false
        )
        
        let request = UNNotificationRequest(
          identifier: UUID().uuidString,
          content: content,
          trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        
        if let task = task {
          task.setTaskCompleted(success: true)
        }
      } else {
        print("Found \(requests.count) pending notification requests; exiting")
        
        if let task = task {
          task.setTaskCompleted(success: false)
        }
      }
    }
  }
}
