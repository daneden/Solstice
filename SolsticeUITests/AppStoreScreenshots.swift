//
//  AppStoreScreenshots.swift
//  SolsticeUITests
//
//  Drives the app through the App Store marketing screens and records a
//  screenshot per screen. Run once per locale by the `Screenshots` test plan —
//  the test itself never mentions a locale. Every element is located by
//  accessibility identifier (see ScreenshotSupport.swift), never by localized
//  text, so the exact same flow works in every language.
//
//  The flow forces a demo location selection on launch (so the app opens
//  straight into the detail view — deterministic, no fragile list-row tap), then
//  backs out to the list and into settings.
//

import UIKit
import XCTest

final class AppStoreScreenshots: XCTestCase {
	override func setUpWithError() throws {
		continueAfterFailure = false
	}

	@MainActor
	func testCaptureAppStoreScreenshots() async throws {
		try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "iPhone marketing flow")
		let app = XCUIApplication()
		app.launchArguments = [ScreenshotLaunch.flag]
		app.launchEnvironment[ScreenshotLaunch.selectedLocationKey] = ScreenshotFixtures.selectedLocationUUID
		app.launchEnvironment[ScreenshotLaunch.displayEpochKey] = String(ScreenshotFixtures.dailyDisplayDate.timeIntervalSince1970)
		app.launch()

		// 02 — Detail view, daily overview (opens directly to the forced selection)
		let detail = app.match(A11y.detailScreen)
		XCTAssertTrue(detail.waitForExistence(timeout: 30), "Detail view never appeared")
		try await settle()
		capture(app, named: "02-detail-daily")

		// 03 — Detail view, annual overview (scroll down to the annual section)
		let annualChart = app.match(A11y.annualChart)
		app.scrollUp(toReveal: annualChart)
		// Fail loudly if the scroll never moved: a consumed drag otherwise captures
		// 03 as a byte-identical copy of 02 and the run still "passes".
		XCTAssertTrue(annualChart.exists && annualChart.frame.minY < app.frame.midY,
		              "Annual chart never scrolled into view — 03 would duplicate 02")
		try await settle()
		capture(app, named: "03-detail-annual")

		// 01 — Location list (back out of the detail view)
		app.buttons["BackButton"].tap()
		let settingsButton = app.buttons[A11y.settingsButton]
		XCTAssertTrue(settingsButton.waitForExistence(timeout: 15), "Locations list never appeared")
		try await settle()
		capture(app, named: "01-location-list")

		// 05 — Notification settings (Settings → Notifications)
		settingsButton.tap()
		try await settle()
		let notificationsLink = app.match(A11y.notificationsLink)
		// The Notifications row sits below the fold in a lazily-rendered Form, so its
		// row isn't in the accessibility tree until scrolled into view — and localized
		// labels make the list taller in some languages. Scroll it in before asserting,
		// mirroring the annual-chart step above.
		app.scrollDown(untilHittable: notificationsLink)
		XCTAssertTrue(notificationsLink.waitForExistence(timeout: 15), "Notifications link never appeared")
		notificationsLink.tap()
		try await settle()
		capture(app, named: "05-notifications")

		// 04 — Time-travelled detail view: relaunch with a Time Machine offset so the
		// app opens straight into a detail view a few months ahead, pinned to New
		// York's sunset moment on the target date.
		app.terminate()
		app.launchEnvironment[ScreenshotLaunch.timeOffsetDaysKey] = String(ScreenshotFixtures.timeTravelOffsetDays)
		app.launchEnvironment[ScreenshotLaunch.displayEpochKey] = String(ScreenshotFixtures.timeTravelDisplayDate.timeIntervalSince1970)
		app.launch()
		let travelledDetail = app.match(A11y.detailScreen)
		XCTAssertTrue(travelledDetail.waitForExistence(timeout: 30), "Travelled detail view never appeared")
		try await settle()
		capture(app, named: "04-time-travel")
	}

	/// iPad marketing flow — matches the Figma "iPadOS Screenshot" template variants:
	/// a light portrait overview (sidebar + detail) and a dark portrait shot of the
	/// notification settings sheet. Portrait, because the template's device bezel is
	/// portrait (the marketing canvas itself is landscape).
	@MainActor
	func testCaptureIPadAppStoreScreenshots() async throws {
		try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad marketing flow")

		XCUIDevice.shared.orientation = .portrait

		let app = XCUIApplication()
		app.launchArguments = [ScreenshotLaunch.flag]
		app.launchEnvironment[ScreenshotLaunch.selectedLocationKey] = ScreenshotFixtures.selectedLocationUUID
		app.launchEnvironment[ScreenshotLaunch.displayEpochKey] = String(ScreenshotFixtures.dailyDisplayDate.timeIntervalSince1970)
		app.launch()

		// ipad-01 — Overview: split view with the sidebar and the forced selection's
		// detail both visible.
		let detail = app.match(A11y.detailScreen)
		XCTAssertTrue(detail.waitForExistence(timeout: 30), "Detail view never appeared")
		var settingsButton = app.buttons[A11y.settingsButton]
		if !settingsButton.isHittable {
			// The sidebar collapsed (e.g. a stale column-visibility state); reveal it.
			app.buttons["ToggleSidebar"].firstMatch.tap()
			XCTAssertTrue(settingsButton.waitForExistence(timeout: 15), "Sidebar never appeared")
		}
		try await settle()
		capture(app, named: "ipad-01-overview")

		// ipad-02 — Notification settings sheet, dark appearance. Relaunch with the
		// scheme forced in-process (UITEST_APPEARANCE): flipping the simulator's
		// appearance mid-test via XCUIDevice doesn't reach the running app.
		app.terminate()
		app.launchEnvironment[ScreenshotLaunch.appearanceKey] = "dark"
		app.launch()
		XCTAssertTrue(app.match(A11y.detailScreen).waitForExistence(timeout: 30), "Detail view never reappeared")
		settingsButton = app.buttons[A11y.settingsButton]
		XCTAssertTrue(settingsButton.waitForExistence(timeout: 15), "Settings button never appeared")
		settingsButton.tap()
		try await settle()
		let notificationsLink = app.match(A11y.notificationsLink)
		app.scrollDown(untilHittable: notificationsLink)
		XCTAssertTrue(notificationsLink.waitForExistence(timeout: 15), "Notifications link never appeared")
		notificationsLink.tap()
		try await settle()
		capture(app, named: "ipad-02-notifications")
	}

	// MARK: - Helpers

	@MainActor
	private func capture(_ app: XCUIApplication, named name: String) {
		let attachment = XCTAttachment(screenshot: app.screenshot())
		attachment.name = name
		attachment.lifetime = .keepAlways
		add(attachment)
	}

	/// Brief pause to let animations/layout settle before a screenshot.
	private func settle() async throws {
		try await Task.sleep(for: .seconds(1))
	}
}

@MainActor
private extension XCUIApplication {
	/// Locates an element by accessibility identifier regardless of its element type.
	func match(_ identifier: String) -> XCUIElement {
		descendants(matching: .any).matching(identifier: identifier).firstMatch
	}

	/// Swipes up until `element` is actually on screen (hittable), best-effort.
	func scrollDown(untilHittable element: XCUIElement, maxSwipes: Int = 8) {
		var swipes = 0
		while !element.isHittable, swipes < maxSwipes {
			swipeUp()
			swipes += 1
		}
	}

	/// Swipes up until `element`'s top edge rises above the screen's vertical
	/// midpoint, genuinely bringing it into view. A large element (e.g. the annual
	/// chart) can report `isHittable == true` while only peeking from the bottom
	/// edge, so `scrollDown(untilHittable:)` would stop without scrolling and
	/// capture the same frame as the previous screen — this forces real movement.
	/// The drag start must thread a needle: `swipeUp()`'s mid-screen start lands
	/// on the daily chart and gets consumed by its scrubbing gesture, while the
	/// bottom ~15–18% (locale-dependent) is covered by the always-visible Time
	/// Travel overlay, which swallows drags without scrolling. dy 0.75 sits on
	/// the detail list rows in every locale.
	func scrollUp(toReveal element: XCUIElement, maxSwipes: Int = 10) {
		var swipes = 0
		while swipes < maxSwipes {
			if element.exists, element.isHittable, element.frame.minY < frame.midY {
				return
			}
			let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
			let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
			start.press(forDuration: 0.05, thenDragTo: end)
			swipes += 1
		}
	}
}
