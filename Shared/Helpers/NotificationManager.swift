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
      self.scheduleNotifications()
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
    
    DispatchQueue.main.async {
      self.scheduleNotifications()
    }
  }
  
  // MARK: Notification scheduler
  func scheduleNotifications(from task: BGAppRefreshTask? = nil) {
    self.getPending { requests in
      for index in 1..<64 {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: self.notifTime))
        let targetDate = Calendar.current.date(byAdding: .day, value: index, to: now)!
        let targetNotificationTime = Calendar.current.date(
          bySettingHour: components.hour ?? 8,
          minute: components.minute ?? 0,
          second: 0,
          of: targetDate
        )!
        
        // Generate an ID for this notification and remove any current pending
        // notifs for the same target time
        let id = targetNotificationTime.description
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        
        let content = UNMutableNotificationContent()
        
        let triggerDate = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: targetNotificationTime)
        
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: triggerDate,
          repeats: false
        )
        
        let notifContent = self.buildNotificationContent(for: targetNotificationTime)
        content.title = notifContent.title
        content.body = notifContent.body
        
        let request = UNNotificationRequest(
          identifier: id,
          content: content,
          trigger: trigger
        )
          
        UNUserNotificationCenter.current().add(request) { error in
          if let error = error {
            print(error.localizedDescription)
          }
        }
      }
      
      if let task = task {
        task.setTaskCompleted(success: true)
      }
    }
  }
  
  // MARK: Notification content builder
  func buildNotificationContent(for date: Date) -> NotificationContent {
    var content = (title: "", body: "")
    
    let solsticeCalculator = SolarCalculator(baseDate: date)
    let suntimes = solsticeCalculator.today
    let duration = suntimes.duration.colloquialTimeString
    let difference = suntimes.difference(from: solsticeCalculator.yesterday)
    let differenceString = difference.colloquialTimeString
    
    let components = Calendar.current.dateComponents([.hour], from: date)
    let hour = components.hour ?? 0
    if hour >= 18 || hour < 3 {
      content.title = "Good Evening"
    } else if hour >= 3 && hour < 12 {
      content.title = "Good Morning"
    } else if hour >= 12 && hour < 18 {
      content.title = "Good Afternoon"
    } else {
      content.title = "Today’s Daylight"
    }
    
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    
    if self.notifsIncludeSunTimes {
      content.body += "The sun rises at \(formatter.string(from: suntimes.begins)) "
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
    
    /**
     Fallthrough for when notification settings specify no content
     */
    if !self.notifsIncludeDaylightChange && !self.notifsIncludeDaylightDuration && !self.notifsIncludeSolsticeCountdown && !self.notifsIncludeSunTimes {
      content.body += "Open Solstice to see how today’s daylight has changed."
    }
    
    return content
  }
}

typealias NotificationContent = (title: String, body: String)
