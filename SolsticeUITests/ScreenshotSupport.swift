//
//  ScreenshotSupport.swift
//  SolsticeUITests
//
//  Mirror of `Solstice/Helpers/ScreenshotSupport.swift`. The UI-test target
//  cannot import the app module, so these identifiers and launch keys are
//  duplicated here. The string values MUST match the app copy exactly.
//

import Foundation

/// Accessibility identifiers for elements captured in App Store screenshots.
enum A11y {
	static let settingsButton = "settings-button"
	static let notificationsLink = "notifications-link"
	static let detailScreen = "detail-screen"
	static let annualChart = "annual-chart"
	static let settingsWindow = "settings-window"

	/// Identifier for a saved-location row, keyed by the location's UUID string.
	static func locationRow(_ uuid: String) -> String {
		"location-row-\(uuid)"
	}
}

/// Launch arguments/environment the app honors ONLY while capturing screenshots.
enum ScreenshotLaunch {
	static let flag = "-UITestScreenshots"
	static let selectedLocationKey = "UITEST_SELECTED_LOCATION"
	static let timeOffsetDaysKey = "UITEST_TIME_OFFSET_DAYS"
	static let displayEpochKey = "UITEST_DISPLAY_EPOCH"
	static let appearanceKey = "UITEST_APPEARANCE"
}

/// The demo location the capture test opens. Its UUID is pre-seeded in
/// `defaultData.json` (`SavedLocation.nycUUIDString`).
enum ScreenshotFixtures {
	static let selectedLocationUUID = "7AAA4D87-4402-4D0E-A35E-2D84641A71BE"

	/// All display instants are expressed in the demo location's timezone so
	/// what the shots show is anchored to New York, not to the machine running
	/// the captures. Explicitly Gregorian: the test process runs once per locale
	/// configuration, and ar/ja configurations default to non-Gregorian calendars.
	private static var newYorkCalendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
		return calendar
	}

	/// The next October 26 — chosen for New York's autumn sunset palette.
	private static var timeTravelDay: Date {
		newYorkCalendar.nextDate(
			after: .now,
			matching: DateComponents(month: 10, day: 26),
			matchingPolicy: .nextTime
		) ?? .now
	}

	/// The exact instant the daily/annual/list/notification shots display:
	/// today at 2:00 PM in New York. Pinned so every locale in a run shows the
	/// same local time and sun position — a full 10-locale run takes long enough
	/// that the sun visibly moves (and can set) between the first and last locale.
	static var dailyDisplayDate: Date {
		newYorkCalendar.date(bySettingHour: 14, minute: 0, second: 0, of: .now) ?? .now
	}

	/// The exact instant the time-travel shot displays: sunset in New York on
	/// the next October 26 (18:01:46 EDT in 2026; drifts under a minute between
	/// years), putting the sun half above / half below the chart's horizon.
	static var timeTravelDisplayDate: Date {
		newYorkCalendar.date(bySettingHour: 18, minute: 1, second: 46, of: timeTravelDay) ?? timeTravelDay
	}

	/// Whole days between today and the time-travel date, keeping the Time
	/// Machine panel's offset engaged and the "compared to today" baseline real.
	static var timeTravelOffsetDays: Int {
		let calendar = newYorkCalendar
		let today = calendar.startOfDay(for: .now)
		let target = calendar.startOfDay(for: timeTravelDay)
		return calendar.dateComponents([.day], from: today, to: target).day ?? 92
	}
}
