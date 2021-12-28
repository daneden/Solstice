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
import Solar

class NotificationManager: NSObject, ObservableObject {
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
    backgroundDispatchQueue.async {
      print("Rebuilding and scheduling notifications")
      self.scheduleNotifications()
    }
  }
  
  // MARK: Notification scheduler
  func scheduleNotifications(from task: BGAppRefreshTask? = nil) {
    /**
     This function should only fully execute if the user has granted notification permissions and the app’s
     `notificationsEnabled` preference is `true`, otherwise we should exit and remove any pending
     notification requests
     */
    notificationCenter.getNotificationSettings { settings in
      guard (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) ||
          self.notificationsEnabled
      else {
        self.notificationCenter.removeAllPendingNotificationRequests()
        task?.setTaskCompleted(success: true)
        return
      }
    }
    
    /**
     We want to get pending requests so we can avoid scheduling duplicate notifications.
     */
    getPending { existingRequests in
      let locationManager = LocationManager.shared
      /**
       `UNUserNotificationCenter` limits scheduling to up to 64 requests. We’ll use that full
       allowance since most users probably won’t be regularly opening the app.
       */
      for index in 0..<64 {
        /**
         We’ll schedule one notification per day for the next 64 days, including today
         */
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
          let solar = Solar(for: date, coordinate: locationManager.coordinate)!
          let chosenEvent = self.relation == .sunset ? solar.ends : solar.begins
          notificationTriggerDate = chosenEvent.addingTimeInterval(self.relativeOffset * (self.relativity == .before ? -1 : 1))
        }
        
        /**
         Skip notifications scheduled for a date/time in the past
         */
        if notificationTriggerDate.isInPast {
          continue
        }
        
        /**
         Create a unique ID based on the scheduled date of the notification
         */
        let idComponents = Calendar.current.dateComponents([.day, .month, .year], from: notificationTriggerDate)
        let id = "me.daneden.Solstice.notification.\(idComponents.year!)-\(idComponents.month!)-\(idComponents.day!)"
        
        let content = UNMutableNotificationContent()
        
        let triggerDate = Calendar.current.dateComponents([.hour, .minute, .day, .month], from: notificationTriggerDate)
        
        let trigger = UNCalendarNotificationTrigger(
          dateMatching: triggerDate,
          repeats: false
        )
        
        guard let notifContent = self.buildNotificationContent(for: notificationTriggerDate) else {
          task?.setTaskCompleted(success: false)
          return
        }
        
        content.title = notifContent.title
        content.body = notifContent.body
        
        let request = UNNotificationRequest(
          identifier: id,
          content: content,
          trigger: trigger
        )
        
        /**
         Avoid scheduling duplicate notifications. This checks to see whether there’s a notification with the
         same ID (i.e. scheduled for the same date), and then checks whether their contents and triggers
         are equal.
         */
        if let requestWithMatchingId = existingRequests.first(where: { $0.identifier == id }),
           request.isApproximatelyEqual(to: requestWithMatchingId) {
          print("Found existing notification, exiting early")
          continue
        } else {
          /**
           This condition may match if there’s a notification with the same ID, but not the same contents/trigger,
           in which case we’ll remove the duplicate and schedule our new notification.
           */
          self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
          self.notificationCenter.add(request) { error in
            if let error = error {
              print(error.localizedDescription)
            }
          }
        }
      }
      
      print("Done scheduling notifications")
      
      task?.setTaskCompleted(success: true)
    }
  }
  
  // MARK: Notification content builder
  /// Creates notification content from a given date. Can be used either for legitimate notifications or for
  /// notification previews.
  /// - Parameters:
  ///   - date: The date for which to generate sunrise/sunset information.
  ///   - context: The context in which this content will be used. This is to ensure that SAD preferences
  ///   don't alter notification previews.
  /// - Returns: A `NotificationContent` object appropriate for the context
  func buildNotificationContent(for date: Date, in context: Context = .notification) -> NotificationContent? {
    var content = (title: "", body: "")
    let locationManager = LocationManager.shared
    let solar = Solar(for: date, coordinate: locationManager.coordinate)!
    let yesterday = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: date)!
    let yesterdaySolar = Solar(for: yesterday, coordinate: locationManager.coordinate)!
    
    let duration = solar.duration.localizedString
    let difference = solar.difference(from: yesterdaySolar)
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
      content.body += "The sun rises at \(solar.begins.formatted(.dateTime.hour().minute())) "
      content.body += "and sets at \(solar.ends.formatted(.dateTime.hour().minute())). "
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
      content.body += "The next solstice is \(Date.nextSolstice(from: date).formatted(.relative(presentation: .named))). "
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

extension NotificationManager {
  typealias NotificationContent = (title: String, body: String)
  
  enum Context {
    case preview, notification
  }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
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
}
