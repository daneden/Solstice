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
import StoreKit

class AppDelegate: NSObject, UIApplicationDelegate {
  private var storeKitTaskHandle: Task<Void, Error>?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    storeKitTaskHandle = listenForStoreKitUpdates()
    
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
      print("Scheduled background task")
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
  
  func listenForStoreKitUpdates() -> Task<Void, Error> {
    Task.detached {
      for await result in Transaction.updates {
        switch result {
        case .verified(let transaction):
          print("Transaction verified in listener")
          
          await transaction.finish()
          
          // Update the user's purchases...
        case .unverified:
          print("Transaction unverified")
        }
      }
    }
  }
}
