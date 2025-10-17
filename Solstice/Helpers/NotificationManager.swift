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
	@AppStorage(Preferences.NotificationSettings.notificationDateComponents) static var notificationDateComponents
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
	
	static func scheduleNotifications(currentLocation: CurrentLocation) async {
		// Always clear notifications when scheduling new ones
		await clearScheduledNotifications()
		
		guard (currentLocation.isAuthorized || customNotificationLocationUUID != nil), notificationsEnabled else {
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
			location = currentLocation.location
		}
		
		guard let location else {
			print("Could not retrieve user location")
			return
		}
		
		for i in 0...63 {
			let date = calendar.date(byAdding: .day, value: i, to: Date()) ?? .now
			
			guard let solar = Solar(for: date, coordinate: location.coordinate) else {
				continue
			}
			
			let notificationDate = getNextNotificationDate(after: date, with: solar)
			
			guard let notificationContent = buildNotificationContent(for: notificationDate, location: location, timeZone: timeZone) else {
				return
			}
			
			let content = UNMutableNotificationContent()
			
			content.title = notificationContent.title
			content.body = notificationContent.body
			
			var components = calendar.dateComponents([.hour, .minute, .day, .month], from: notificationDate)
			components.timeZone = .autoupdatingCurrent
			
			let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
			
			let request = UNNotificationRequest(identifier: "me.daneden.Solstice.notification-\(notificationDate.ISO8601Format())", content: content, trigger: trigger)
			
			do {
				try await UNUserNotificationCenter.current().add(request)
			} catch {
				print(error)
			}
		}
	}
	
	static func getNextNotificationDate(after date: Date, with solar: Solar? = nil) -> Date {
		if scheduleType == .specificTime {
			let hour = notificationDateComponents.hour ?? 0
			let minute = notificationDateComponents.minute ?? 0
			return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
		} else {
			guard let solar else { return date }
			let relativeDate = scheduleType == .sunset ? solar.safeSunset : solar.safeSunrise
			let offsetDate = relativeDate.addingTimeInterval(userPreferenceNotificationOffset)
			let scheduleComponents = calendar.dateComponents([.hour, .minute], from: offsetDate)
			return calendar.date(
				bySettingHour: scheduleComponents.hour ?? 0,
				minute: scheduleComponents.minute ?? 0,
				second: 0, of: date
			) ?? date
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
		let difference = solar.daylightDuration - (solar.yesterday?.daylightDuration ?? 0)
		let differenceString = difference.localizedString
		
		if difference < 0 && sadPreference == .suppressNotifications && context != .preview {
			return nil
		}
		
		let year = calendar.component(.year, from: date)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		let marchEquinox = SolsticeCalculator.marchEquinox(year: year)
		let septemberEquinox = SolsticeCalculator.septemberEquinox(year: year)
		
		if calendar.isDate(date, inSameDayAs: marchEquinox) {
			content.title = NSLocalizedString("March Equinox Today", comment: "Notification title for March equinox")
		} else if calendar.isDate(date, inSameDayAs: septemberEquinox) {
			content.title = NSLocalizedString("September Equinox Today", comment: "Notification title for September equinox")
		} else if calendar.isDate(date, inSameDayAs: juneSolstice) {
			content.title = NSLocalizedString("June Solstice Today", comment: "Notification title for June solstice")
		} else if calendar.isDate(date, inSameDayAs: decemberSolstice) {
			content.title = NSLocalizedString("December Solstice Today", comment: "Notification title for December solstice")
		} else {
			let components = calendar.dateComponents([.hour], from: date)
			let hour = components.hour ?? 0
			if hour >= 18 || hour < 3 {
				content.title = NSLocalizedString("Good Evening", comment: "Notification title for evening notification")
			} else if hour >= 3 && hour < 12 {
				content.title = NSLocalizedString("Good Morning", comment: "Notification title for morning notification")
			} else if hour >= 12 && hour < 18 {
				content.title = NSLocalizedString("Good Afternoon", comment: "Notification title for afternoon notification")
			} else {
				content.title = NSLocalizedString("Today’s Daylight", comment: "Notification title fallback")
			}
		}
		
		@StringBuilder var notificationBody: String {
			if includeSunTimes {
				let sunriseTime = solar.safeSunrise.withTimeZoneAdjustment(for: timeZone).formatted(.dateTime.hour().minute())
				let sunsetTime = solar.safeSunset.withTimeZoneAdjustment(for: timeZone).formatted(.dateTime.hour().minute())
				let sunriseSunset = NSLocalizedString(
					"notif-sunrise-sunset",
					value: "The sun rises at %1$@ and sets at %2$@.",
					comment: "Notification fragment for sunrise and sunset times"
				)
				
				String.localizedStringWithFormat(sunriseSunset, sunriseTime, sunsetTime)
			}
			
			if includeDaylightDuration {
				let daylightDuration = NSLocalizedString(
					"notif-daylight-duration",
					value: "%@ of daylight today.",
					comment: "Notification fragment for length of daylight"
				)
				String.localizedStringWithFormat(daylightDuration, duration)
			}
			
			if includeDaylightChange {
				if !(difference < 0 && sadPreference == .removeDifference) || context == .preview {
					if difference >= 0 {
						let moreDaylightFormat = NSLocalizedString("notif-more-daylight", value: "%@ more daylight than yesterday.", comment: "Notification fragment for more daylight compared to yesterday")
						String.localizedStringWithFormat(moreDaylightFormat, differenceString)
					} else {
						let lessDaylightFormat = NSLocalizedString("notif-less-daylight", value: "%@ less daylight than yesterday.", comment: "Notification fragment for less daylight compared to yesterday")
						String.localizedStringWithFormat(lessDaylightFormat, differenceString)
					}
				}
			}
			
			if !includeDaylightChange && !includeDaylightDuration && !includeSolsticeCountdown && !includeSunTimes {
				NSLocalizedString(
					"Open Solstice to see how today’s daylight has changed.",
					comment: "Fallthrough notification content for when notification settings specify no content."
				)
			}
		}
		
		content.body = notificationBody
		
		return content
	}
}

extension NotificationManager {
	typealias NotificationContent = (title: String, body: String)
	
	enum Context {
		case preview, notification
	}
}
