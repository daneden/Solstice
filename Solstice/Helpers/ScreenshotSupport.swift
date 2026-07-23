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
import SwiftUI

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
/// Nothing here has any effect in a normal (non-capture) launch.
enum ScreenshotLaunch {
	/// Launch argument that switches the app into deterministic screenshot mode
	/// (in-memory seeded store, no CloudKit dependency, no location permission).
	static let flag = "-UITestScreenshots"

	/// Environment key: UUID string of the saved location to open on launch.
	static let selectedLocationKey = "UITEST_SELECTED_LOCATION"

	/// Environment key: integer number of days to offset the Time Machine by.
	static let timeOffsetDaysKey = "UITEST_TIME_OFFSET_DAYS"

	/// Environment key: force "dark" or "light" appearance for the capture launch.
	/// The simulator-level `XCUIDevice.shared.appearance` doesn't reliably reach a
	/// running app, so the dark marketing shots force the scheme in-process instead.
	static let appearanceKey = "UITEST_APPEARANCE"

	/// Environment key: which macOS screen to open directly into for window capture.
	static let macScreenKey = "UITEST_MAC_SCREEN"

	/// macOS capture opens the app straight into one of these states (the `open` +
	/// screencapture pipeline can't drive the UI, so the app presents it on launch).
	/// The default (no value) is the daily detail view.
	enum MacScreen: String {
		case detailAnnual = "detail-annual"
		case settingsNotifications = "settings-notifications"
	}

	/// Environment key: which visionOS scene to present for window capture (the
	/// simctl-driven pipeline can't drive the UI, so the app presents it on launch).
	static let visionScreenKey = "UITEST_VISION_SCREEN"

	/// visionOS capture states beyond the default main window.
	enum VisionScreen: String {
		case solsticeInfo = "solstice-info"
	}

	static var isCapturing: Bool {
		ProcessInfo.processInfo.arguments.contains(flag)
	}

	static var forcedSelectedLocation: String? {
		ProcessInfo.processInfo.environment[selectedLocationKey]
	}

	static var timeOffsetDays: Int? {
		ProcessInfo.processInfo.environment[timeOffsetDaysKey].flatMap(Int.init)
	}

	static var macScreen: MacScreen? {
		ProcessInfo.processInfo.environment[macScreenKey].flatMap(MacScreen.init(rawValue:))
	}

	static var visionScreen: VisionScreen? {
		ProcessInfo.processInfo.environment[visionScreenKey].flatMap(VisionScreen.init(rawValue:))
	}

	/// Color scheme to force during capture, or nil for the system appearance
	/// (always nil outside screenshot mode, so this never affects normal launches).
	static var forcedColorScheme: ColorScheme? {
		guard isCapturing else { return nil }
		switch ProcessInfo.processInfo.environment[appearanceKey] {
		case "dark": return .dark
		case "light": return .light
		default: return nil
		}
	}

	/// Prepares deterministic defaults for screenshot capture. Call once at launch
	/// before any view evaluates. No-op unless `-UITestScreenshots` is set.
	static func prepareForCaptureIfNeeded() {
		guard isCapturing else { return }
		let defaults = UserDefaults(suiteName: Constants.appGroupIdentifier)
		// Skip the first-launch onboarding sheet so the app opens straight into content.
		defaults?.set(true, forKey: Preferences.hasCompletedOnboarding.key)
		// Show the notification settings in their enabled state for the screenshot.
		defaults?.set(true, forKey: Preferences.notificationsEnabled.key)
		// Show the Time Machine panel only on the time-travel launch (offset set);
		// otherwise hide it so the daily/annual shots aren't cluttered.
		let appearance: TimeTravelAppearance = timeOffsetDays != nil ? .expanded : .hidden
		defaults?.set(appearance.rawValue, forKey: Preferences.timeTravelAppearance.key)

		seedLocalizedFixtureNames()
	}

	/// Pre-seeds the localized-name cache for the fixture locations from a frozen,
	/// human-reviewed JSON, so localized names render deterministically with no live
	/// geocoding during capture. Keyed by the same coordinate bucket the resolver uses,
	/// for the current process locale (each test-plan configuration runs in its own).
	private static func seedLocalizedFixtureNames() {
		guard let url = Bundle.main.url(forResource: "screenshot-localized-names", withExtension: "json"),
		      let data = try? Data(contentsOf: url),
		      let byCoord = try? JSONDecoder().decode([String: [String: [String: String]]].self, from: data)
		else { return }

		// Map the process locale to a table key by language code. The table has one key
		// per shipping language (only "zh-Hans" carries a script), so match the code
		// exactly or by prefix — robust to how iOS/macOS resolve the script (iOS test-plan
		// configs vary it, which previously left non-ja/ar locales unmatched → English).
		let code = Locale.current.language.languageCode?.identifier ?? "en"
		let available = byCoord.values.flatMap(\.keys)
		guard let localeKey = available.first(where: { $0 == code || $0.hasPrefix("\(code)-") }) else { return }

		for (coordKey, byLocale) in byCoord {
			guard let entry = byLocale[localeKey] else { continue }
			LocalizedNameCache.write(
				key: "\(coordKey)|\(Locale.current.identifier)",
				title: entry["title"],
				subtitle: entry["subtitle"]
			)
		}
	}
}
