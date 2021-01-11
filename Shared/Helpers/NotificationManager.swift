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

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
  @AppStorage(UDValues.notificationTime.key, store: solsticeUDStore)
  var notifTime: TimeInterval = UDValues.notificationTime.value
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("Presenting notification! Assuming this was a daily notif, scheduling the next one...")
    
    DispatchQueue.global(qos: .background).async {
      self.scheduleNotification()
    }
  }
  
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
        
        if let hour = components.hour, hour >= 18 || hour < 3 {
          content.title = "Good Evening"
        } else if let hour = components.hour, hour >= 3 && hour < 12 {
          content.title = "Good Morning"
        } else if let hour = components.hour, hour >= 12 && hour < 18 {
          content.title = "Good Afternoon"
        } else {
          content.title = "Today’s Daylight"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        if let suntimes = solsticeCalculator.today {
          let components = suntimes.durationComponents
          let duration = suntimes.differenceComponents(from: solsticeCalculator.yesterday ?? suntimes)
          let hour = components.hour ?? 0
          let minute = components.minute ?? 0
          content.body = "The sun rises at \(formatter.string(from: suntimes.begins ?? Date())) "
          content.body += "and sets at \(formatter.string(from: suntimes.ends ?? Date())); "
          content.body += "\(hour)hrs and \(minute)mins of daylight today. "
          content.body += "That’s \(duration.minutes) mins and \(duration.seconds) secs \(suntimes.difference(from: solsticeCalculator.yesterday ?? suntimes) > 0 ? "more" : "less") than yesterday."
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
