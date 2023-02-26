//
//  AppStorage++.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI
import Solar

fileprivate let defaultNotificationDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!

extension AppStorage {
	init(_ kv: AppStorageKVPair<Value>) where Value == String {
		self.init(wrappedValue: kv.value, kv.key, store: .standard)
	}
	
	init(_ kv: AppStorageKVPair<Value>) where Value == Bool {
		self.init(wrappedValue: kv.value, kv.key, store: .standard)
	}
	
	init(_ kv: AppStorageKVPair<Value>) where Value == TimeInterval {
		self.init(wrappedValue: kv.value, kv.key, store: .standard)
	}
	
	init(_ kv: AppStorageKVPair<Value>) where Value: RawRepresentable, Value.RawValue == String {
		self.init(wrappedValue: kv.value, kv.key, store: .standard)
	}
}

extension Optional: RawRepresentable where Wrapped: Codable {
	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
					let json = String(data: data, encoding: .utf8)
		else {
			return "{}"
		}
		return json
	}
	
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
					let value = try? JSONDecoder().decode(Self.self, from: data)
		else {
			return nil
		}
		self = value
	}
}

typealias AppStorageKVPair<T> = (key: String, value: T)

struct Preferences {
	typealias Value = AppStorageKVPair
	
	// MARK: Notifications
	/// The user preference for whether notifications are enabled
	static let notificationsEnabled: Value = ("notifsEnabled", false)
	
	/// The user preference for whether notifications include sunrise/sunset times
	static let notificationsIncludeSunTimes: Value = ("notifsIncludeSunTimes", true)
	
	/// The user preference for whether notifications include the daylight duration
	static let notificationsIncludeDaylightDuration: Value = ("notifsIncludeDaylightDuration", true)
	
	/// The user preference for whether notifications include the change in daylight compared to yesterday
	static let notificationsIncludeDaylightChange: Value = ("notifsIncludeDaylightChange", true)
	
	/// The user preference for whether notifications include the time until the next solstice
	static let notificationsIncludeSolsticeCountdown: Value = ("notifsIncludeSolsticeCountdown", false)
	
	/// The user preference for how notifications are altered during periods of lessening daylight
	static let sadPreference: Value<SADPreference> = ("sadPreverence", .none)
	
	// MARK: Scheduling
	struct NotificationSettings {
		/// The type of notification schedule; either a specific time (specified in `notificationDate`) or relative to sunrise/sunset
		static let scheduleType: Value<ScheduleType> = ("notificationScheduleType", .specificTime)
		
		/// The date/time for notification scheduling. Only the time will be used.
		static let notificationTime: Value<Date> = ("notifTime", defaultNotificationDate)
		
		/// Which solar event notifications are sent relative to
		static let relation: Value<Solar.Phase> = ("notificationRelation", .sunrise)
		
		/// The offset in seconds between the notification and the chosen solar event
		static let relativeOffset: Value<TimeInterval> = ("notificationRelativeOffset", 30 * 60)
		
		/// The preset offsets for relative notification times
		static let relativeOffsetDetents: Array<TimeInterval> = [
			-4 * 60 * 60,
			 -3 * 60 * 60,
			 -2 * 60 * 60,
			 -1 * 60 * 60,
			 -45 * 60,
			 -30 * 60,
			 -15 * 60,
			 0,
			 15 * 60,
			 30 * 60,
			 45 * 60,
			 60 * 60,
			 2 * 60 * 60,
			 3 * 60 * 60,
			 4 * 60 * 60
		]
	}
	
	// MARK: App Appearance
	static var appColorScheme: Value<SolsticeColorScheme> = ("appColorScheme", .system)
}

extension Preferences {
	enum SolsticeColorScheme: String, CaseIterable, RawRepresentable {
		case system = "Automatic (System)"
		case dark = "Dark"
		case light = "Light"
		case locationBased = "Automatic (Location Daylight)"
	}
}

extension Preferences {
	enum SADPreference: String, CaseIterable, RawRepresentable {
		case none = "No change"
		case removeDifference = "Remove daylight gain/loss"
		case suppressNotifications = "Suppress notifications altogether"
	}
}

extension Preferences.NotificationSettings {
	enum ScheduleType: String, RawRepresentable, CaseIterable {
		case specificTime, sunset, sunrise
		
		var description: String {
			switch self {
			case .specificTime:
				return "a specific time"
			case .sunset:
				return "Sunset"
			case .sunrise:
				return "Sunrise"
			}
		}
	}
}