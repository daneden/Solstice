//
//  NotificationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 23/02/2023.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
	static var backgroundTaskIdentifier = "me.daneden.Solstice.notificationScheduler"
	
	static func requestAuthorization() async -> Bool? {
		return try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
	}
	
	static func scheduleNotification() {
		let content = UNMutableNotificationContent()
		content.title = "Feed the cat"
		content.subtitle = "It looks hungry"
		content.sound = UNNotificationSound.default
		
		// show this notification five seconds from now
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
		
		// choose a random identifier
		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
		
		// add our notification request
		UNUserNotificationCenter.current().add(request)
	}
}
