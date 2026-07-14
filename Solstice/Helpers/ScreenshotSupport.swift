//
//  ScreenshotSupport.swift
//  Solstice
//
//  Accessibility identifiers and launch configuration shared with the UI-test
//  target for App Store screenshot capture. Screenshot navigation must never
//  depend on localized text, so every element the capture test touches is
//  located by one of these identifiers.
//
//  NOTE: The UI-test target cannot import the app module, so it keeps a small
//  mirror of `A11y` and `ScreenshotLaunch` in `SolsticeUITests/ScreenshotSupport.swift`.
//  Keep the two in sync — the string values must match exactly.
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
/// Nothing here has any effect in a normal (non-capture) launch.
enum ScreenshotLaunch {
    /// Launch argument that switches the app into deterministic screenshot mode
    /// (in-memory seeded store, no CloudKit dependency, no location permission).
    static let flag = "-UITestScreenshots"

    /// Environment key: UUID string of the saved location to open on launch.
    static let selectedLocationKey = "UITEST_SELECTED_LOCATION"

    /// Environment key: integer number of days to offset the Time Machine by.
    static let timeOffsetDaysKey = "UITEST_TIME_OFFSET_DAYS"

    static var isCapturing: Bool {
        ProcessInfo.processInfo.arguments.contains(flag)
    }

    static var forcedSelectedLocation: String? {
        ProcessInfo.processInfo.environment[selectedLocationKey]
    }

    static var timeOffsetDays: Int? {
        ProcessInfo.processInfo.environment[timeOffsetDaysKey].flatMap(Int.init)
    }
}
