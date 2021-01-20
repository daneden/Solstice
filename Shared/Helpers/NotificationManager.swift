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
  // General notification settings
  @AppStorage(UDValues.notificationTime) var notifTime
  
  // Notification fragment settings
  @AppStorage(UDValues.notificationsIncludeSunTimes) var notifsIncludeSunTimes
  @AppStorage(UDValues.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
  @AppStorage(UDValues.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
  @AppStorage(UDValues.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
  
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
          self.adjustSchedule()
          
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
    self.notificationCenter.removeAllPendingNotificationRequests()
    self.scheduleNotification()
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
        
        let content = UNMutableNotificationContent()
        
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: Calendar.current.dateComponents([.hour, .minute], from: targetNotificationTime),
          repeats: false
        )
        
        let notifContent = self.buildNotificationContent()
        content.title = notifContent.title
        content.body = notifContent.body
        
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
        print(requests)
        
        if let task = task {
          task.setTaskCompleted(success: false)
        }
      }
    }
  }
  
  func buildNotificationContent() -> NotificationContent {
    var content = (title: "", body: "")
    let now = Date()
    let components = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: self.notifTime))
    let targetDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    
    let solsticeCalculator = SolarCalculator(baseDate: targetDate)
    let suntimes = solsticeCalculator.today
    let duration = suntimes.duration.colloquialTimeString
    let difference = suntimes.difference(from: solsticeCalculator.yesterday)
    let differenceString = difference.colloquialTimeString
    
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
    
    if self.notifsIncludeSunTimes {
      content.body = "The sun rises at \(formatter.string(from: suntimes.begins)) "
      content.body += "and sets at \(formatter.string(from: suntimes.ends)). "
    }
    
    if self.notifsIncludeDaylightDuration {
      content.body += "\(duration) of daylight today. "
    }
    
    if self.notifsIncludeDaylightChange {
      content.body += "\(differenceString) \(difference >= 0 ? "more" : "less") daylight than yesterday. "
    }
    
    if self.notifsIncludeSolsticeCountdown {
      let formatter = RelativeDateTimeFormatter()
      let string = formatter.localizedString(for: solsticeCalculator.nextSolstice, relativeTo: Date())
      content.body += "The next solstice is \(string). "
    }
    
    if !self.notifsIncludeDaylightChange && !self.notifsIncludeDaylightDuration && !self.notifsIncludeSolsticeCountdown && !self.notifsIncludeSunTimes {
      content.body += "Open Solstice to see how today’s daylight has changed."
    }
    
    return content
  }
}

typealias NotificationContent = (title: String, body: String)
