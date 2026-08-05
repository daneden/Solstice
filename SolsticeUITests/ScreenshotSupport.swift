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

	/// June 1 of the current year in New York. Anchoring the daily shots to a
	/// fixed early-summer day (not "today") means a capture run at any hour,
	/// anywhere, never shoots a pre-sunrise or wintry New York — and unlike the
	/// solstice itself, daylight is still growing fast (~1 min/day), so the
	/// "more daylight today" summary shows a healthy number.
	private static var anchorDay: Date {
		let year = newYorkCalendar.component(.year, from: .now)
		return newYorkCalendar.date(from: DateComponents(year: year, month: 6, day: 1)) ?? .now
	}

	/// October 26 of the same year — chosen for New York's autumn sunset palette.
	private static var timeTravelDay: Date {
		let year = newYorkCalendar.component(.year, from: .now)
		return newYorkCalendar.date(from: DateComponents(year: year, month: 10, day: 26)) ?? .now
	}

	/// The exact instant the daily/annual/list/notification shots display:
	/// June 1 at 12:41 PM in New York (9:41 AM Pacific — Apple's marketing
	/// time). Pinned so every locale in a run shows the same local time and sun
	/// position — a full 10-locale run takes long enough that the sun visibly
	/// moves (and can set) between the first and last locale.
	static var dailyDisplayDate: Date {
		newYorkCalendar.date(bySettingHour: 12, minute: 41, second: 0, of: anchorDay) ?? anchorDay
	}

	/// The exact instant the time-travel shot displays: sunset in New York on
	/// the next October 26 (18:01:46 EDT in 2026; drifts under a minute between
	/// years), putting the sun half above / half below the chart's horizon.
	static var timeTravelDisplayDate: Date {
		newYorkCalendar.date(bySettingHour: 18, minute: 1, second: 46, of: timeTravelDay) ?? timeTravelDay
	}

	/// Whole days between the pinned June 1 "today" and the time-travel date.
	/// The time-travel relaunch walks the reference date back by this offset, so
	/// the app's "today" stays June 1 while the Time Machine is engaged onto
	/// the October sunset — the daily shots (offset 0) keep it visibly inactive.
	static var timeTravelOffsetDays: Int {
		let calendar = newYorkCalendar
		let base = calendar.startOfDay(for: anchorDay)
		let target = calendar.startOfDay(for: timeTravelDay)
		return calendar.dateComponents([.day], from: base, to: target).day ?? 147
	}
}
