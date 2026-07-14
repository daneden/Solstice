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
}

/// The demo location the capture test opens. Its UUID is pre-seeded in
/// `defaultData.json` (`SavedLocation.nycUUIDString`).
enum ScreenshotFixtures {
	static let selectedLocationUUID = "7AAA4D87-4402-4D0E-A35E-2D84641A71BE"

	/// Days into the future for the time-travel screenshot (~3 months ahead so the
	/// daylight figures visibly differ from "today").
	static let timeTravelOffsetDays = 92
}
