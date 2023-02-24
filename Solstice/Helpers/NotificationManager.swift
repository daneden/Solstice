//
//  NotificationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 23/02/2023.
//

import Foundation
import UserNotifications
import CoreLocation
import Solar

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
	static var backgroundTaskIdentifier = "me.daneden.Solstice.notificationScheduler"
	
	static func requestAuthorization() async -> Bool? {
		return try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
	}
	
	static func scheduleNotification() async {
		guard CurrentLocation.isAuthorized else { return }
		
		let location: CLLocation? = await withCheckedContinuation({ continuation in
			CurrentLocation().requestLocation { location in
				continuation.resume(returning: location)
			}
		})
		
		guard let location else {
			print("Could not retrieve user location")
			return
		}
		
		guard let notificationContent = buildNotificationContent(for: Date(), location: location) else {
			return
		}
		
		let content = UNMutableNotificationContent()
		content.title = notificationContent.title
		content.subtitle = notificationContent.body
		
		let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .day, .month], from: Date().addingTimeInterval(5))
		
		let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
		
		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
		
		// add our notification request
		do {
			try await UNUserNotificationCenter.current().add(request)
		} catch {
			print(error)
		}
	}
	
	// MARK: Notification content builder
	/// Creates notification content from a given date. Can be used either for legitimate notifications or for
	/// notification previews.
	/// - Parameters:
	///   - date: The date for which to generate sunrise/sunset information.
	///   - location: The location for sunrise/sunset times
	///   - context: The context in which this content will be used. This is to ensure that SAD preferences
	///   don't alter notification previews.
	/// - Returns: A `NotificationContent` object appropriate for the context
	static func buildNotificationContent(for date: Date, location: CLLocation, in context: Context = .notification) -> NotificationContent? {
		var content = (title: "", body: "")
		let solar = Solar(for: date, coordinate: location.coordinate)!
		
		let duration = solar.daylightDuration.localizedString
		let difference = solar.daylightDuration - solar.yesterday.daylightDuration
		let differenceString = difference.localizedString
		
//		if difference < 0 && sadPreference == .suppressNotifications && context != .preview {
//			return nil
//		}
		
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
		
//		if self.notifsIncludeSunTimes {
//			content.body += "The sun rises at \(solar.begins.formatted(.dateTime.hour().minute())) "
//			content.body += "and sets at \(solar.ends.formatted(.dateTime.hour().minute())). "
//		}
		
//		if self.notifsIncludeDaylightDuration {
			content.body += "\(duration) of daylight today. "
//		}
		
//		if self.notifsIncludeDaylightChange {
//			if !(difference < 0 && sadPreference == .removeDifference) || context == .preview {
//				content.body += "\(differenceString) \(difference >= 0 ? "more" : "less") daylight than yesterday. "
//			}
//		}
		
//		if self.notifsIncludeSolsticeCountdown {
//			content.body += "The next solstice is \(Date.nextSolstice(from: date).formatted(.relative(presentation: .named))). "
//		}
		
		/**
		 Fallthrough for when notification settings specify no content
		 */
//		if !self.notifsIncludeDaylightChange && !self.notifsIncludeDaylightDuration && !self.notifsIncludeSolsticeCountdown && !self.notifsIncludeSunTimes {
//			content.body += "Open Solstice to see how today’s daylight has changed."
//		}
		
		return content
	}
}

extension NotificationManager {
	typealias NotificationContent = (title: String, body: String)
	
	enum Context {
		case preview, notification
	}
}
