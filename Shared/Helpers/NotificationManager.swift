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
  static let shared = NotificationManager()
  
  // General notification settings
  @AppStorage(UDValues.NotificationSettings.notificationTime) var notifTime
  @AppStorage(UDValues.notificationsEnabled) var notificationsEnabled
  
  // Notification fragment settings
  @AppStorage(UDValues.notificationsIncludeSunTimes) var notifsIncludeSunTimes
  @AppStorage(UDValues.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
  @AppStorage(UDValues.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
  @AppStorage(UDValues.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
  @AppStorage(UDValues.sadPreference) var sadPreference
  
  @AppStorage(UDValues.NotificationSettings.scheduleType) var scheduleType
  @AppStorage(UDValues.NotificationSettings.relation) var relation
  @AppStorage(UDValues.NotificationSettings.relativeOffset) var relativeOffset
  @AppStorage(UDValues.NotificationSettings.relativity) var relativity
  
  private let backgroundDispatchQueue = DispatchQueue(
    label: "me.daneden.Solstice.backgroundDispatchQueue",
    qos: .background,
    attributes: [],
    autoreleaseFrequency: .workItem,
    target: nil
  )
  
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("Presenting notification! Assuming this was a daily notif, scheduling the next one...")
    
    DispatchQueue.global(qos: .background).async {
      self.scheduleNotifications()
    }
  }
  
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    self.notificationCenter.removeAllDeliveredNotifications()
  }
  
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
      self.removePendingNotificationRequests()
    }
  }
  
  func removeDeliveredNotifications() {
    print("Removing delivered notifications")
    notificationCenter.removeAllDeliveredNotifications()
  }
  
  func removePendingNotificationRequests() {
    print("Removing scheduled notifications")
    notificationCenter.removeAllPendingNotificationRequests()
  }
  
  func rescheduleNotifications() {
    self.removePendingNotificationRequests()
    
    backgroundDispatchQueue.async {
      print("Rebuilding and scheduling notifications")
      self.scheduleNotifications()
    }
  }
  
  // MARK: Notification scheduler
  func scheduleNotifications(from task: BGAppRefreshTask? = nil) {
    notificationCenter.getNotificationSettings { settings in
      guard (settings.authorizationStatus == .authorized && settings.authorizationStatus == .provisional) ||
          self.notificationsEnabled
      else {
        self.notificationCenter.removeAllPendingNotificationRequests()
        return
      }
    }
    
    getPending { existingRequests in
      // UNUserNotificationCenter only lets you schedule up to 64 notifications,
      // so we’ll use that full threshold
      let solarCalculator = SolarCalculator()
      
      for index in 1..<64 {
        var notificationTriggerDate: Date
        let targetDate = Calendar.current.date(byAdding: .day, value: index, to: .now)!
        
        
        switch self.scheduleType {
        case .specificTime:
          let components = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: self.notifTime))
          notificationTriggerDate = Calendar.current.date(
            bySettingHour: components.hour ?? 8,
            minute: components.minute ?? 0,
            second: 0,
            of: targetDate
          )!
        case .relativeTime:
          let date = Calendar.current.date(byAdding: .day, value: index, to: .now)!
          solarCalculator.baseDate = date
          let chosenEvent = self.relation == .sunset ? solarCalculator.today.ends : solarCalculator.today.begins
          notificationTriggerDate = chosenEvent.addingTimeInterval(self.relativeOffset * (self.relativity == .before ? -1 : 1))
        }
        
        let idComponents = Calendar.current.dateComponents([.day, .month, .year], from: notificationTriggerDate)
        let id = "me.daneden.Solstice.notification.\(idComponents.year!)-\(idComponents.month!)-\(idComponents.day!)"
        
        let content = UNMutableNotificationContent()
        
        let triggerDate = Calendar.current.dateComponents(Set(Calendar.Component.allCases), from: notificationTriggerDate)
        
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: triggerDate,
          repeats: false
        )
        
        guard let notifContent = self.buildNotificationContent(for: notificationTriggerDate) else {
          if let task = task {
            task.setTaskCompleted(success: true)
          }
          return
        }
        
        content.title = notifContent.title
        content.body = notifContent.body
        
        let request = UNNotificationRequest(
          identifier: id,
          content: content,
          trigger: trigger
        )
        
        // Avoid scheduling identical notifications
        if let requestWithMatchingId = existingRequests.first(where: { $0.identifier == id }),
           request.isApproximatelyEqual(to: requestWithMatchingId) {
          print("Found existing notification, exiting early")
          task?.setTaskCompleted(success: true)
          return
        } else {
          self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
          
          self.notificationCenter.add(request) { error in
            if let error = error {
              print(error.localizedDescription)
            } else {
              print("Scheduled notification #\(index): \(request.identifier) at \(triggerDate.date?.formatted() ?? "unknown date")")
            }
          }
        }
      }
      
      task?.setTaskCompleted(success: true)
    }
  }
  
  enum Context {
    case preview, notification
  }
  
  // MARK: Notification content builder
  func buildNotificationContent(for date: Date, in context: Context = .notification) -> NotificationContent? {
    var content = (title: "", body: "")
    
    let solsticeCalculator = SolarCalculator(baseDate: date)
    let suntimes = solsticeCalculator.today
    let duration = suntimes.duration.localizedString
    let difference = suntimes.difference(from: solsticeCalculator.yesterday)
    let differenceString = difference.localizedString
    
    if difference < 0 && sadPreference == .suppressNotifications && context != .preview {
      return nil
    }
    
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
    
    if self.notifsIncludeSunTimes {
      content.body += "The sun rises at \(suntimes.begins.formatted(.dateTime.hour().minute())) "
      content.body += "and sets at \(suntimes.ends.formatted(.dateTime.hour().minute())). "
    }
    
    if self.notifsIncludeDaylightDuration {
      content.body += "\(duration) of daylight today. "
    }
    
    if self.notifsIncludeDaylightChange {
      if !(difference < 0 && sadPreference == .removeDifference) || context == .preview {
        content.body += "\(differenceString) \(difference >= 0 ? "more" : "less") daylight than yesterday. "
      }
    }
    
    if self.notifsIncludeSolsticeCountdown {
      content.body += "The next solstice is \(solsticeCalculator.nextSolstice.formatted(.relative(presentation: .named))). "
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

extension UNNotificationRequest {
  func isApproximatelyEqual(to otherRequest: UNNotificationRequest) -> Bool {
    guard let selfTrigger = self.trigger, let otherTrigger = otherRequest.trigger else {
      return false
    }
    
    return (
      self.identifier == otherRequest.identifier &&
      self.content.title == otherRequest.content.title &&
      self.content.body == otherRequest.content.body &&
      selfTrigger.hashValue == otherTrigger.hashValue
    )
  }
}
