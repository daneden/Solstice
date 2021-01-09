//
//  AppDelegate.swift
//  Solstice
//
//  Created by Daniel Eden on 09/01/2021.
//

import Foundation
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "me.daneden.Solstice.notificationScheduler", using: nil) { task in
      self.handleBackgroundNotificationScheduling(task: task as! BGAppRefreshTask)
    }
    
    return true
  }
  
  func handleBackgroundNotificationScheduling(task: BGAppRefreshTask) {
    let notificationManager = NotificationManager.shared
    
    notificationManager.scheduleNotification(from: task)
    
    task.expirationHandler = {
      print("Unable to schedule notification")
    }
    
    
  }
}
