//
//  AppDelegate.swift
//  Solstice
//
//  Created by Daniel Eden on 09/01/2021.
//

import Foundation
import UIKit
import BackgroundTasks
import Intents

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "me.daneden.Solstice.notificationScheduler", using: nil) { task in
      self.handleBackgroundNotificationScheduling(task: task as! BGAppRefreshTask)
    }
    
    DispatchQueue.global(qos: .background).async {
      self.submitBackgroundTask()
    }
    
    return true
  }
  
  func submitBackgroundTask() {
    let task = BGAppRefreshTaskRequest(identifier: "me.daneden.Solstice.notificationScheduler")
    task.earliestBeginDate = Date(timeIntervalSinceNow: 60)
    
    do {
      try BGTaskScheduler.shared.submit(task)
    } catch {
      print("Unable to submit task: \(error.localizedDescription)")
    }
  }
  
  func handleBackgroundNotificationScheduling(task: BGAppRefreshTask) {
    let notificationManager = NotificationManager.shared
    
    notificationManager.scheduleNotifications(from: task)
    
    task.expirationHandler = {
      print("Unable to schedule notification")
    }
  }
}
