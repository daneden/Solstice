//
//  NotificationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 23/02/2023.
//

import Foundation
import UserNotifications
import CoreLocation
import SwiftUI
import CoreData
#if os(iOS) && !WIDGET_EXTENSION
import BackgroundTasks
#endif

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
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
	
	static var backgroundTaskIdentifier = Constants.backgroundTaskIdentifier
	
	static func requestAuthorization() async -> Bool? {
		return try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
	}
	
	static func clearScheduledNotifications() async {
		return UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}
	
	static func clearDeliveredNotifications() async {
		return UNUserNotificationCenter.current().removeAllDeliveredNotifications()
	}
	
	/// Schedules notifications for the next 64 days
	/// - Parameter location: Optional location to use. If nil, will attempt to fetch current location.
	static func scheduleNotifications(location existingLocation: CLLocation? = nil) async {
		await clearScheduledNotifications()

		guard notificationsEnabled else { return }

		var location: CLLocation?
		var timeZone = localTimeZone

		// Check for custom notification location first
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
		} else if let existingLocation {
			// Use the provided location
			location = existingLocation
		} else {
			// Fetch current location using async API
			do {
				location = try await CurrentLocation.fetchCurrentLocation()
			} catch {
				print("Could not fetch location: \(error.localizedDescription)")
				return
			}
		}

		guard let location else {
			print("Could not retrieve location for notification scheduling")
			return
		}

		for i in 0...63 {
			let date = calendar.date(byAdding: .day, value: i, to: Date()) ?? .now

			guard let solar = NTSolar(for: date, coordinate: location.coordinate, timeZone: timeZone) else {
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
			let request = UNNotificationRequest(identifier: "\(Constants.notificationIdentifierPrefix)\(notificationDate.ISO8601Format())", content: content, trigger: trigger)

			do {
				try await UNUserNotificationCenter.current().add(request)
			} catch {
				print(error)
			}
		}

		#if os(iOS) && !WIDGET_EXTENSION
		scheduleBackgroundTask()
		#endif
	}

	// MARK: Background Task Management

	#if os(iOS) && !WIDGET_EXTENSION
	/// Schedules the next background app refresh task
	/// This should be called after scheduling notifications to ensure periodic refresh
	static func scheduleBackgroundTask() {
		let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)

		// Schedule to run after at least 1 day to catch location changes sooner
		request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)

		do {
			try BGTaskScheduler.shared.submit(request)
			print("Background task scheduled successfully for notification refresh")
		} catch let error as BGTaskScheduler.Error {
			switch error.code {
			case .unavailable:
				// This is expected in the simulator or when the app is in the foreground
				print("Background task scheduling unavailable (expected in simulator)")
			case .tooManyPendingTaskRequests:
				print("Too many pending background task requests")
			case .notPermitted:
				print("Background task not permitted - check Info.plist configuration")
			default:
				print("Failed to schedule background task: \(error.localizedDescription)")
			}
		} catch {
			print("Failed to schedule background task: \(error.localizedDescription)")
		}
	}
	#endif

	static func getNextNotificationDate(after date: Date, with solar: NTSolar? = nil) -> Date {
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
	
	// MARK: - Notification Content Building

	/// Creates notification content from a given date. Can be used either for legitimate notifications or for
	/// notification previews.
	/// - Parameters:
	///   - date: The date for which to generate sunrise/sunset information.
	///   - location: The location for sunrise/sunset times
	///   - timeZone: The time zone for formatting times
	///   - context: The context in which this content will be used. This is to ensure that SAD preferences
	///   don't alter notification previews.
	/// - Returns: A `NotificationContent` object appropriate for the context
	static func buildNotificationContent(for date: Date, location: CLLocation, timeZone: TimeZone = .autoupdatingCurrent, in context: Context = .notification) -> NotificationContent? {
		guard let solar = NTSolar(for: date, coordinate: location.coordinate, timeZone: timeZone) else { return nil }

		let difference = solar.daylightDuration - (solar.yesterday?.daylightDuration ?? 0)

		// Check if we should suppress the notification entirely (SAD preference)
		if shouldSuppressNotification(difference: difference, context: context) {
			return nil
		}

		let title = buildNotificationTitle(for: date)
		let body = buildNotificationBody(solar: solar, timeZone: timeZone, difference: difference, date: date, context: context)

		return NotificationContent(title: title, body: body)
	}

	// MARK: SAD Preference Handling

	/// Determines if the notification should be suppressed based on SAD preferences
	private static func shouldSuppressNotification(difference: TimeInterval, context: Context) -> Bool {
		guard context != .preview else { return false }
		return difference < 0 && sadPreference == .suppressNotifications
	}

	/// Determines if daylight change should be hidden based on SAD preferences
	private static func shouldHideDaylightChange(difference: TimeInterval, context: Context) -> Bool {
		guard context != .preview else { return false }
		return difference < 0 && sadPreference == .removeDifference
	}

	// MARK: Title Generation

	/// Generates the notification title based on the date
	private static func buildNotificationTitle(for date: Date) -> String {
		// Check for special solar events first
		if let solarEventTitle = solarEventTitle(for: date) {
			return solarEventTitle
		}

		// Fall back to time-of-day greeting
		return greetingTitle(for: date)
	}

	/// Returns a title if the date falls on a solstice or equinox
	private static func solarEventTitle(for date: Date) -> String? {
		let year = calendar.component(.year, from: date)

		let solarEvents: [(date: Date, title: String)] = [
			(SolsticeCalculator.marchEquinox(year: year),
			 NSLocalizedString("March Equinox Today", comment: "Notification title for March equinox")),
			(SolsticeCalculator.septemberEquinox(year: year),
			 NSLocalizedString("September Equinox Today", comment: "Notification title for September equinox")),
			(SolsticeCalculator.juneSolstice(year: year),
			 NSLocalizedString("June Solstice Today", comment: "Notification title for June solstice")),
			(SolsticeCalculator.decemberSolstice(year: year),
			 NSLocalizedString("December Solstice Today", comment: "Notification title for December solstice"))
		]

		return solarEvents.first { calendar.isDate(date, inSameDayAs: $0.date) }?.title
	}

	/// Returns a greeting based on the time of day
	private static func greetingTitle(for date: Date) -> String {
		let hour = calendar.component(.hour, from: date)

		switch hour {
		case 0..<3, 18...23:
			return NSLocalizedString("Good Evening", comment: "Notification title for evening notification")
		case 3..<12:
			return NSLocalizedString("Good Morning", comment: "Notification title for morning notification")
		case 12..<18:
			return NSLocalizedString("Good Afternoon", comment: "Notification title for afternoon notification")
		default:
			return NSLocalizedString("Today's Daylight", comment: "Notification title fallback")
		}
	}

	// MARK: Body Generation

	/// Builds the notification body with all enabled content fragments
	private static func buildNotificationBody(solar: NTSolar, timeZone: TimeZone, difference: TimeInterval, date: Date, context: Context) -> String {
		let duration = solar.daylightDuration.localizedString
		let differenceString = difference.localizedString

		@StringBuilder var body: String {
			if includeSunTimes {
				sunTimesFragment(solar: solar, timeZone: timeZone)
			}

			if includeDaylightDuration {
				daylightDurationFragment(duration: duration)
			}

			if includeDaylightChange && !shouldHideDaylightChange(difference: difference, context: context) {
				daylightChangeFragment(difference: difference, differenceString: differenceString)
			}

			if includeSolsticeCountdown, let countdown = solsticeCountdownFragment(for: date) {
				countdown
			}

			if !includeDaylightChange && !includeDaylightDuration && !includeSolsticeCountdown && !includeSunTimes {
				NSLocalizedString(
					"Open Solstice to see how today's daylight has changed.",
					comment: "Fallthrough notification content for when notification settings specify no content."
				)
			}
		}

		return body
	}

	// MARK: Body Fragments

	private static func sunTimesFragment(solar: NTSolar, timeZone: TimeZone) -> String {
		let sunriseTime = solar.safeSunrise.withTimeZoneAdjustment(for: timeZone).formatted(.dateTime.hour().minute())
		let sunsetTime = solar.safeSunset.withTimeZoneAdjustment(for: timeZone).formatted(.dateTime.hour().minute())
		let format = NSLocalizedString(
			"notif-sunrise-sunset",
			value: "The sun rises at %1$@ and sets at %2$@.",
			comment: "Notification fragment for sunrise and sunset times"
		)
		return String.localizedStringWithFormat(format, sunriseTime, sunsetTime)
	}

	private static func daylightDurationFragment(duration: String) -> String {
		let format = NSLocalizedString(
			"notif-daylight-duration",
			value: "%@ of daylight today.",
			comment: "Notification fragment for length of daylight"
		)
		return String.localizedStringWithFormat(format, duration)
	}

	private static func daylightChangeFragment(difference: TimeInterval, differenceString: String) -> String {
		if difference >= 0 {
			let format = NSLocalizedString("notif-more-daylight", value: "%@ more daylight than yesterday.", comment: "Notification fragment for more daylight compared to yesterday")
			return String.localizedStringWithFormat(format, differenceString)
		} else {
			let format = NSLocalizedString("notif-less-daylight", value: "%@ less daylight than yesterday.", comment: "Notification fragment for less daylight compared to yesterday")
			return String.localizedStringWithFormat(format, differenceString)
		}
	}

	private static func solsticeCountdownFragment(for date: Date) -> String? {
		let year = calendar.component(.year, from: date)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)

		let nextJuneSolstice = juneSolstice > date ? juneSolstice : SolsticeCalculator.juneSolstice(year: year + 1)
		let nextDecemberSolstice = decemberSolstice > date ? decemberSolstice : SolsticeCalculator.decemberSolstice(year: year + 1)
		let nextSolstice = nextJuneSolstice < nextDecemberSolstice ? nextJuneSolstice : nextDecemberSolstice
		let isJuneSolstice = nextSolstice == nextJuneSolstice

		guard let daysUntil = calendar.dateComponents([.day], from: date, to: nextSolstice).day, daysUntil > 0 else {
			return nil
		}

		let solsticeName = isJuneSolstice
			? NSLocalizedString("June solstice", comment: "Name of June solstice")
			: NSLocalizedString("December solstice", comment: "Name of December solstice")
		let format = NSLocalizedString(
			"notif-solstice-countdown",
			value: "%lld days until the %@.",
			comment: "Notification fragment for days until next solstice"
		)
		return String.localizedStringWithFormat(format, daysUntil, solsticeName)
	}
}

extension NotificationManager {
	struct NotificationContent {
		let title: String
		let body: String
	}
	
	enum Context {
		case preview, notification
	}
}
