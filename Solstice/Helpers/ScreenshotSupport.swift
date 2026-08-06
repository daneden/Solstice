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
import Observation
import SwiftUI
import TimeMachine
#if canImport(AppKit)
	import AppKit
#endif

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

	/// Environment key: epoch seconds of the exact instant the UI should display.
	/// Pins the TimeMachine's clock for the whole launch — without it, time-of-day
	/// tracks the wall clock, and a long multi-locale capture run drifts the sun's
	/// position between the first and last locale. Combine with
	/// `UITEST_TIME_OFFSET_DAYS` to keep the Time Machine panel engaged while the
	/// displayed date and time stay exact.
	static let displayEpochKey = "UITEST_DISPLAY_EPOCH"

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

	static var displayDate: Date? {
		ProcessInfo.processInfo.environment[displayEpochKey]
			.flatMap(TimeInterval.init)
			.map(Date.init(timeIntervalSince1970:))
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
		// Show the notification settings in their enabled state for the screenshot.
		defaults?.set(true, forKey: Preferences.notificationsEnabled.key)
		// Always show Time Travel UI
		defaults?.set(TimeTravelAppearance.expanded.rawValue, forKey: Preferences.timeTravelAppearance.key)
		// Pin the daily chart to the classic design: @AppStorage reads the app-group
		// suite, so whatever chart the simulator last used would otherwise leak into
		// the marketing shots.
		defaults?.set(ChartType.classic.rawValue, forKey: Preferences.chartType.key)

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

/// Applies the deterministic state each screenshot needs, and — while capturing —
/// keeps applying it as new commands arrive.
///
/// This lives here rather than in `ContentView` because it is capture scaffolding,
/// not content: it was ~50 near-identical lines in each of the iOS/macOS and watchOS
/// content views, and every line of it is inert in a normal launch.
struct ScreenshotCaptureModifier: ViewModifier {
	@SceneStorage("selectedLocation") private var selectedLocation: String?
	@Environment(\.timeMachine) private var timeMachine: TimeMachine

	#if !os(watchOS)
		@Environment(\.openWindow) private var openWindow
		@Environment(\.dismissWindow) private var dismissWindow
	#endif

	#if DEBUG
		/// Reading `generation` in `body` is what registers the observation, so a
		/// command written by the capture host re-runs `apply()`.
		private var director = CaptureDirector.shared
	#endif

	func body(content: Content) -> some View {
		#if DEBUG
			content
				.task(id: director.generation) { await apply() }
				.task { await director.watchForCommands() }
		#else
			content.task { await apply() }
		#endif
	}

	private func apply() async {
		guard ScreenshotLaunch.isCapturing else { return }

		#if DEBUG
			let forcedSelection = director.selectedLocation
			let offsetDays = director.timeOffsetDays
			let display = director.displayDate
			let macScreen = director.macScreen
			let visionScreen = director.visionScreen
		#else
			let forcedSelection = ScreenshotLaunch.forcedSelectedLocation
			let offsetDays = ScreenshotLaunch.timeOffsetDays ?? 0
			let display = ScreenshotLaunch.displayDate
			let macScreen = ScreenshotLaunch.macScreen
			let visionScreen = ScreenshotLaunch.visionScreen
		#endif

		// Honor the forced selection, otherwise start on the list (ignoring any stale
		// SceneStorage selection).
		selectedLocation = forcedSelection

		if let display {
			// Pin the displayed instant exactly: referenceDate + offset must land on
			// `display`, so derive the reference by walking the offset back. Without the
			// pin, time-of-day tracks the wall clock and a long multi-locale run drifts
			// the sun's position between the first and last locale.
			let reference = Calendar.current.date(byAdding: .day, value: -offsetDays, to: display) ?? display
			timeMachine.updateReferenceDate(to: reference)
		}
		timeMachine.offset = Double(offsetDays)

		#if os(macOS)
			// Force the app frontmost so its window is presented for capture.
			NSApplication.shared.activate(ignoringOtherApps: true)
			// The SwiftUI Settings scene can't be opened programmatically, so the
			// settings shot uses a dedicated DEBUG-only window.
			#if DEBUG
				if macScreen == .settingsNotifications {
					try? await Task.sleep(for: .milliseconds(400))
					openWindow(id: "capture-settings")
				}
			#endif
		#endif

		// This file is compiled into the widget extensions too, which don't carry the
		// app's scene types — hence the WIDGET_EXTENSION guard rather than os(visionOS)
		// alone.
		#if os(visionOS) && !WIDGET_EXTENSION
			// Present the "About solstices and equinoxes" window for its marketing shot.
			// The main window stays open behind — dismissing it leaves the info window
			// permanently dimmed (unfocused), and its glass backdrop is what gives the
			// front window its solid, readable look.
			if visionScreen == .solsticeInfo {
				try? await Task.sleep(for: .milliseconds(400))
				openWindow(value: AnnualSolarEvent.juneSolstice)
			}
		#endif

		// Referenced only under the platform guards above; keep the bindings used so
		// every platform compiles warning-free.
		_ = macScreen
		_ = visionScreen
	}
}

extension View {
	/// Drives this view's screenshot-capture state. No-op in a normal launch.
	func capturingScreenshots() -> some View {
		modifier(ScreenshotCaptureModifier())
	}
}

extension View {
	/// Appearance and window size the marketing shots need. Both resolve to "no
	/// opinion" in a normal launch: `forcedColorScheme` is nil outside capture, and
	/// a nil width/height leaves the window free to size and resize as usual.
	func screenshotPresentation() -> some View {
		preferredColorScheme(ScreenshotLaunch.forcedColorScheme)
		#if os(macOS)
			.frame(
				width: ScreenshotLaunch.isCapturing ? 800 : nil,
				height: ScreenshotLaunch.isCapturing ? 600 : nil
			)
		#endif
	}
}

extension Scene {
	/// Window behaviour the macOS capture needs.
	///
	/// Passing -AppleLanguages to force the capture locale makes AppKit relaunch the
	/// app, and that relaunch restores the prior (zero-window) state instead of
	/// presenting the main window. Disable restoration and force presentation while
	/// capturing; normal launches keep system behaviour.
	func screenshotWindowBehavior() -> some Scene {
		#if os(macOS)
			restorationBehavior(ScreenshotLaunch.isCapturing ? .disabled : .automatic)
				.defaultLaunchBehavior(ScreenshotLaunch.isCapturing ? .presented : .automatic)
		#else
			self
		#endif
	}
}

extension View {
	/// Injects the shared TimeMachine. When a capture pins the displayed instant
	/// (`UITEST_DISPLAY_EPOCH`), the environment is set directly — skipping
	/// `withTimeMachine`'s minutely reference-date ticker, which would overwrite
	/// the pinned clock within a minute of launch.
	@ViewBuilder
	func withSolsticeTimeMachine() -> some View {
		if ScreenshotLaunch.displayDate != nil {
			environment(\.timeMachine, .solsticeTimeMachine)
		} else {
			withTimeMachine(.solsticeTimeMachine)
		}
	}
}

// MARK: - Driving multiple shots from one process

// Lets one running app produce every screenshot for a locale, instead of a
// fresh launch per shot.
//
// Screens used to be selected purely through launch environment variables, so
// every shot cost a terminate/launch/first-render cycle. Measured on a visionOS
// simulator that cycle is 16-33s locally and around three minutes on a CI
// runner, which is why the visionOS leg alone took two hours for thirty shots —
// the simctl calls themselves are only ~2s. The environment now seeds the
// *initial* state, and the same values can be changed afterwards over the
// a command file the capture host writes into the app's Documents directory:
//
//     echo '{"seq":2,"screen":"solstice-info"}' > "$CONTAINER/Documents/capture-command.json"
//
// A URL (`solstice://capture?...`) would be the obvious channel and the scheme
// is already registered, but `simctl openurl` raises a system "Open in
// Solstice?" confirmation on visionOS, which needs a tap the capture scripts
// cannot give it. A polled file has no such gate and works identically on
// macOS, where the app is unsandboxed.
//
// Locale is deliberately NOT switchable here. SwiftUI resolves `Text` against
// the environment locale, but the app has ten String-based `.formatted(...)`
// call sites — including the daylight-summary headline — that read
// `Locale.current`, the process locale, which no environment override reaches.
// Switching locale in-process would leave those in the launch language and
// produce a screenshot that looks right and is wrong. One launch per locale,
// every screen within it.

#if DEBUG
	@Observable
	final class CaptureDirector {
		static let shared = CaptureDirector()

		var selectedLocation: String?
		var macScreen: ScreenshotLaunch.MacScreen?
		var visionScreen: ScreenshotLaunch.VisionScreen?
		var timeOffsetDays: Int
		var displayDate: Date?

		/// Bumped on every applied command. Views key their capture `task` on this so
		/// a command that repeats a value still re-runs the presentation side effects
		/// (opening a window, say) rather than being coalesced away as "no change".
		private(set) var generation = 0

		private init() {
			selectedLocation = ScreenshotLaunch.forcedSelectedLocation
			macScreen = ScreenshotLaunch.macScreen
			visionScreen = ScreenshotLaunch.visionScreen
			timeOffsetDays = ScreenshotLaunch.timeOffsetDays ?? 0
			displayDate = ScreenshotLaunch.displayDate
		}

		/// The file the host writes commands into.
		///
		/// Simulators: the app's own Documents directory, which the sandbox can read
		/// and the host reaches via
		/// `xcrun simctl get_app_container <udid> me.daneden.Solstice data`.
		///
		static var commandURL: URL? {
			FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
				.appendingPathComponent("capture-command.json")
		}

		/// Defaults key carrying the command JSON on macOS.
		static let commandDefaultsKey = "captureCommand"

		/// Where a command comes from, which differs by platform because of the sandbox.
		///
		/// Simulators: a file in the app's Documents directory, which the host reaches
		/// through `xcrun simctl get_app_container`.
		///
		/// macOS: app-group defaults. The Mac app IS sandboxed — `ENABLE_APP_SANDBOX`
		/// injects the entitlement even though the .entitlements file has no such key —
		/// so its Documents directory is the user's real one and /tmp is unreachable.
		/// Writing a file into the group container fails too: that directory is 0700
		/// and TCC blocks the shell. `defaults write` goes through cfprefsd, which has
		/// the access the shell does not, so that is the channel:
		///
		///     defaults write group.me.daneden.Solstice captureCommand '{"seq":2,…}'
		private func readCommand() -> Data? {
			#if os(macOS)
				guard let defaults = UserDefaults(suiteName: Constants.appGroupIdentifier) else { return nil }
				return defaults.string(forKey: Self.commandDefaultsKey)?.data(using: .utf8)
			#else
				guard let url = Self.commandURL else { return nil }
				return try? Data(contentsOf: url)
			#endif
		}

		private struct Command: Decodable {
			var seq: Int
			var screen: String?
			var location: String?
			var offset: Int?
			var epoch: TimeInterval?
		}

		private var lastSeq = 0

		/// Watches the command file for the whole capture session. Polling rather than
		/// a file-system event: the host writes at human timescales, a 0.25s tick costs
		/// nothing next to a screenshot, and there is no coalescing to reason about.
		func watchForCommands() async {
			guard ScreenshotLaunch.isCapturing else { return }
			while !Task.isCancelled {
				if let data = readCommand(),
				   let command = try? JSONDecoder().decode(Command.self, from: data),
				   command.seq != lastSeq
				{
					lastSeq = command.seq
					apply(command)
				}
				try? await Task.sleep(for: .milliseconds(250))
			}
		}

		/// Every field is optional and omitting one leaves that value alone, so a command
		/// can change just the screen without restating the pinned clock. `screen` is the
		/// exception: it is always reassigned, because returning to the main window is
		/// expressed by sending no screen at all.
		private func apply(_ command: Command) {
			macScreen = command.screen.flatMap(ScreenshotLaunch.MacScreen.init(rawValue:))
			visionScreen = command.screen.flatMap(ScreenshotLaunch.VisionScreen.init(rawValue:))

			if let location = command.location { selectedLocation = location }
			if let offset = command.offset { timeOffsetDays = offset }
			if let epoch = command.epoch { displayDate = Date(timeIntervalSince1970: epoch) }

			generation += 1
		}
	}
#endif
