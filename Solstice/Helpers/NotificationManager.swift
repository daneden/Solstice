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
import SwiftUI
import CoreData

class NotificationManager: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
	@AppStorage(Preferences.notificationsEnabled) static var notificationsEnabled
	@AppStorage(Preferences.notificationsIncludeSunTimes) static var includeSunTimes
	@AppStorage(Preferences.notificationsIncludeDaylightChange) static var includeDaylightChange
	@AppStorage(Preferences.notificationsIncludeDaylightDuration) static var includeDaylightDuration
	@AppStorage(Preferences.notificationsIncludeSolsticeCountdown) static var includeSolsticeCountdown
	@AppStorage(Preferences.NotificationSettings.scheduleType) static var scheduleType
	@AppStorage(Preferences.NotificationSettings.notificationTime) static var userPreferenceNotificationTime
	@AppStorage(Preferences.NotificationSettings.relativeOffset) static var userPreferenceNotificationOffset
	@AppStorage(Preferences.sadPreference) static var sadPreference
	@AppStorage(Preferences.customNotificationLocationUUID) static var customNotificationLocationUUID
	
	static var backgroundTaskIdentifier = "me.daneden.Solstice.notificationScheduler"
	
	static func requestAuthorization() async -> Bool? {
		return try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
	}
	
	static func clearScheduledNotifications() async {
		return UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}
	
	static func clearDeliveredNotifications() async {
		return UNUserNotificationCenter.current().removeAllDeliveredNotifications()
	}
	
	static func scheduleNotifications(locationManager: CurrentLocation) async {
		// Always clear notifications when scheduling new ones
		await clearScheduledNotifications()
		
		guard (CurrentLocation.isAuthorized || customNotificationLocationUUID != nil), notificationsEnabled else {
			return
		}
		
		var location: CLLocation?
		var timeZone = localTimeZone
		
		if let customNotificationLocationUUID {
			let request = NSFetchRequest<SavedLocation>(entityName: "SavedLocation")
			request.fetchLimit = 1
			request.predicate = NSPredicate(format: "uuid LIKE %@", customNotificationLocationUUID)
			let context = PersistenceController.shared.container.viewContext
			let objects = try? context.fetch(request)
			
			if let latitude = objects?.first?.latitude,
				 let longitude = objects?.first?.longitude,
				 let objectTimeZone = objects?.first?.timeZone {
				location = CLLocation(latitude: latitude, longitude: longitude)
				timeZone = objectTimeZone
			}
		} else {
			location = locationManager.latestLocation
		}
		
		if location == nil {
			location = await withCheckedContinuation({ continuation in
				locationManager.requestLocation { location in
					print("Made it to the callback")
					continuation.resume(returning: location)
				}
			})
		}
		
		guard let location else {
			print("Could not retrieve user location")
			return
		}
		
		for i in 0...63 {
			let date = calendar.date(byAdding: .day, value: i, to: Date()) ?? .now
			var notificationDate: Date
			
			guard let solar = Solar(for: date, coordinate: location.coordinate) else {
				continue
			}
			
			if scheduleType == .specificTime {
				let scheduleComponents = calendar.dateComponents([.hour, .minute], from: userPreferenceNotificationTime)
				notificationDate = calendar.date(bySettingHour: scheduleComponents.hour ?? 0, minute: scheduleComponents.minute ?? 0, second: 0, of: date) ?? date
			} else {
				let relativeDate = scheduleType == .sunset ? solar.safeSunset : solar.safeSunrise
				let offsetDate = relativeDate.addingTimeInterval(userPreferenceNotificationOffset)
				let scheduleComponents = calendar.dateComponents([.hour, .minute], from: offsetDate)
				notificationDate = calendar.date(bySettingHour: scheduleComponents.hour ?? 0, minute: scheduleComponents.minute ?? 0, second: 0, of: date) ?? date
			}
			
			guard let notificationContent = buildNotificationContent(for: notificationDate, location: location, timeZone: timeZone) else {
				return
			}
			
			let content = UNMutableNotificationContent()
			
			content.title = notificationContent.title
			content.body = notificationContent.body
			
			let components = calendar.dateComponents([.hour, .minute, .day, .month], from: notificationDate)
			
			let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
			
			let request = UNNotificationRequest(identifier: "me.daneden.Solstice.notification-\(notificationDate.ISO8601Format())", content: content, trigger: trigger)
			
			do {
				try await UNUserNotificationCenter.current().add(request)
				print("Scheduled notification with ID \(request.identifier)")
			} catch {
				print(error)
			}
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
	static func buildNotificationContent(for date: Date, location: CLLocation, timeZone: TimeZone = .autoupdatingCurrent, in context: Context = .notification) -> NotificationContent? {
		var content = (title: "", body: "")
		guard let solar = Solar(for: date, coordinate: location.coordinate) else { return nil }
		
		let duration = solar.daylightDuration.localizedString
		let difference = solar.daylightDuration - solar.yesterday.daylightDuration
		let differenceString = difference.localizedString
		
		if difference < 0 && sadPreference == .suppressNotifications && context != .preview {
			return nil
		}
		
		let year = calendar.component(.year, from: date)
		let juneSolstice = SolsticeCalculator.decemberSolstice(year: year)
		let decemberSolstice = SolsticeCalculator.juneSolstice(year: year)
		let marchEquinox = SolsticeCalculator.marchEquinox(year: year)
		let septemberEquinox = SolsticeCalculator.septemberEquinox(year: year)
		
		if calendar.isDate(date, inSameDayAs: marchEquinox) {
			content.title = "March Equinox Today"
		} else if calendar.isDate(date, inSameDayAs: septemberEquinox) {
			content.title = "September Equinox Today"
		} else if calendar.isDate(date, inSameDayAs: juneSolstice) {
			content.title = "June Solstice Today"
		} else if calendar.isDate(date, inSameDayAs: decemberSolstice) {
			content.title = "December Solstice Today"
		} else {
			let components = calendar.dateComponents([.hour], from: date)
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
		}
		
		if includeSunTimes {
			content.body += "The sun rises at \(solar.safeSunrise.withTimeZoneAdjustment(for: timeZone).formatted(.dateTime.hour().minute())) "
			content.body += "and sets at \(solar.safeSunset.withTimeZoneAdjustment(for: timeZone).formatted(.dateTime.hour().minute())). "
		}
		
		if includeDaylightDuration {
			content.body += "\(duration) of daylight today. "
		}
		
		if includeDaylightChange {
			if !(difference < 0 && sadPreference == .removeDifference) || context == .preview {
				content.body += "\(differenceString) \(difference >= 0 ? "more" : "less") daylight than yesterday. "
			}
		}
		
		if includeSolsticeCountdown {
			content.body += "The next solstice is \(solar.date.nextSolstice.formatted(.relative(presentation: .named))). "
		}
		
		/**
		 Fallthrough for when notification settings specify no content
		 */
		if !includeDaylightChange && !includeDaylightDuration && !includeSolsticeCountdown && !includeSunTimes {
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
