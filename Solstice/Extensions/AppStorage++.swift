//
//  AppStorage++.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI

private let defaultNotificationDate = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? .now

private let store = UserDefaults(suiteName: Constants.appGroupIdentifier)

extension AppStorage {
	init(_ kv: AppStorageKVPair<Value>) where Value == String {
		self.init(wrappedValue: kv.value, kv.key, store: store ?? .standard)
	}

	init(_ kv: AppStorageKVPair<Value>) where Value == Bool {
		self.init(wrappedValue: kv.value, kv.key, store: store ?? .standard)
	}

	init(_ kv: AppStorageKVPair<Value>) where Value == TimeInterval {
		self.init(wrappedValue: kv.value, kv.key, store: store ?? .standard)
	}

	init(_ kv: AppStorageKVPair<Value>) where Value: RawRepresentable, Value.RawValue == String {
		self.init(wrappedValue: kv.value, kv.key, store: store ?? .standard)
	}
}

extension Optional: @retroactive RawRepresentable where Wrapped: Codable {
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

enum Preferences {
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

	/// Which bodies the detail view's charts plot. Global rather than per-location, the
	/// same way `chartType` is.
	static let bodyMode: Value<CelestialBodyMode> = ("detailViewBodyMode", .solar)

	/// The user preference for whether a major solar eclipse produces its own notifications.
	///
	/// Unlike the fragment toggles above this doesn't change the daily notification; it
	/// schedules two extra ones around the eclipse itself. On by default, so the handful
	/// of people whose location is ever in the path don't miss it through not knowing the
	/// setting existed.
	static let notificationsIncludeEclipses: Value = ("notifsIncludeEclipses", true)

	/// The user preference for how notifications are altered during periods of lessening daylight
	static let sadPreference: Value<SADPreference> = ("sadPreverence", .none)

	static let cachedLatitude: Value<Double> = ("cachedLatitude", 0)
	static let cachedLongitude: Value<Double> = ("cachedLongitude", 0)

	static let customNotificationLocationUUID: Value<String?> = ("customNotificationLocationUUID", nil)

	// MARK: Scheduling

	enum NotificationSettings {
		/// The type of notification schedule; either a specific time (specified in `notificationDate`) or relative to sunrise/sunset
		static let scheduleType: Value<ScheduleType> = ("notificationScheduleType", .specificTime)

		/// The date/time for notification scheduling. Only the time will be used.
		static let _notificationTime: Value<Date> = ("notifTime", defaultNotificationDate)

		/// The date components for notification scheduling.
		static let notificationDateComponents: Value<DateComponents> = ("notifDateComponents", NotificationSettings.defaultDateComponents)
		static let defaultDateComponents = DateComponents(timeZone: .autoupdatingCurrent, hour: 8, minute: 0)

		/// Which solar event notifications are sent relative to
		static let relation: Value<NTSolar.Phase> = ("notificationRelation", .sunrise)

		/// The offset in seconds between the notification and the chosen solar event
		static let relativeOffset: Value<TimeInterval> = ("notificationRelativeOffset", 30 * 60)

		/// The preset offsets for relative notification times
		static let relativeOffsetDetents: [TimeInterval] = [
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
			4 * 60 * 60,
		]
	}

	// MARK: Appearance

	enum SortingFunction: String, Codable, RawRepresentable {
		case timezone, daylightDuration
	}

	static let detailViewChartAppearance: Value<DaylightChart.Appearance> = ("detailViewChartAppearance", chartAppearanceDefaultValue)
	static let listViewAppearance: Value<DaylightChart.Appearance> = ("listViewAppearance", .graphical)

	#if !os(watchOS)
		static let listViewSortDimension: Value<SortingFunction> = ("listViewOrderBy", .timezone)
	#endif

	static let listViewSortOrder: Value<SortOrder> = ("listViewSortOrder", .forward)
	static let listViewShowComplication: Value<Bool> = ("listViewShowComplication", showComplicationDefaultValue)

	static let timeTravelAppearance: Value<TimeTravelAppearance> = ("timeTravelAppearance", .expanded)

	static let chartType: Value<ChartType> = ("chartType", .classic)
	static let showSolsticesInChart: Value<Bool> = ("showSolsticesInChart", false)
}

enum TimeTravelAppearance: String, CaseIterable, RawRepresentable, Identifiable {
	case expanded, compact, hidden

	var id: Self {
		self
	}

	var title: LocalizedStringKey {
		switch self {
		case .expanded: return "Classic"
		case .compact: return "Compact"
		case .hidden: return "Hidden"
		}
	}

	#if !os(watchOS)
		var image: ImageResource {
			switch self {
			case .expanded:
				return .timetravelClassic
			case .compact:
				return .timetravelCompact
			case .hidden:
				return .timetravelHidden
			}
		}
	#endif
}

enum ChartType: String, CaseIterable, RawRepresentable, Identifiable {
	case classic, circular

	var title: LocalizedStringKey {
		switch self {
		case .classic: return "Classic"
		case .circular: return "Circular"
		}
	}

	var icon: ImageResource {
		switch self {
		case .classic: return .solarchartLinear
		case .circular: return .solarchartCircularFill
		}
	}

	var id: Self {
		self
	}
}

/// Which bodies the detail view's charts plot.
///
/// The sky gradient stays solar whichever is chosen — it is driven by the sun's altitude,
/// and keeping it as the backdrop is what makes the moon's path legible: you can see at a
/// glance whether the moon is up in darkness or wasted in broad daylight.
enum CelestialBodyMode: String, CaseIterable, RawRepresentable, Identifiable {
	case solar, lunar, both

	var title: LocalizedStringKey {
		switch self {
		case .solar: return "Sun"
		case .lunar: return "Moon"
		case .both: return "Sun and moon"
		}
	}

	var icon: String {
		switch self {
		case .solar: return "sun.max"
		case .lunar: return "moon"
		case .both: return "moon.stars"
		}
	}

	var includesSun: Bool { self != .lunar }
	var includesMoon: Bool { self != .solar }

	/// The next mode in the cycle, for the watchOS toolbar button where a menu is clumsy.
	var next: CelestialBodyMode {
		let all = Self.allCases
		let index = all.firstIndex(of: self) ?? 0
		return all[(index + 1) % all.count]
	}

	var id: Self {
		self
	}
}

extension Preferences {
	enum SADPreference: String, CaseIterable, RawRepresentable {
		case none = "No change"
		case removeDifference = "Remove daylight gain/loss"
		case suppressNotifications = "Suppress notifications altogether"

		var description: LocalizedStringKey {
			switch self {
			case .none:
				return "No change"
			case .removeDifference:
				return "Remove daylight gain/loss"
			case .suppressNotifications:
				return "Suppress notifications altogether"
			}
		}
	}
}

extension Preferences.NotificationSettings {
	enum ScheduleType: String, RawRepresentable, CaseIterable {
		case specificTime, sunset, sunrise

		var description: LocalizedStringKey {
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

extension SortOrder: @retroactive RawRepresentable {
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
		      let result = try? JSONDecoder().decode(SortOrder.self, from: data)
		else {
			return nil
		}
		self = result
	}

	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
		      let result = String(data: data, encoding: .utf8)
		else {
			return ""
		}
		return result
	}

	public typealias RawValue = String
}

private var showComplicationDefaultValue: Bool {
	#if os(macOS)
		true
	#else
		false
	#endif
}

private var chartAppearanceDefaultValue: DaylightChart.Appearance = .graphical
