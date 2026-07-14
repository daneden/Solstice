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

import XCTest

final class AppStoreScreenshots: XCTestCase {
	override func setUpWithError() throws {
		continueAfterFailure = false
	}

	@MainActor
	func testCaptureAppStoreScreenshots() async throws {
		let app = XCUIApplication()
		app.launchArguments = [ScreenshotLaunch.flag]
		app.launchEnvironment[ScreenshotLaunch.selectedLocationKey] = ScreenshotFixtures.selectedLocationUUID
		app.launch()

		// 02 — Detail view, daily overview (opens directly to the forced selection)
		let detail = app.match(A11y.detailScreen)
		XCTAssertTrue(detail.waitForExistence(timeout: 30), "Detail view never appeared")
		try await settle()
		capture(app, named: "02-detail-daily")

		// 03 — Detail view, annual overview (scroll down to the annual section)
		app.scrollDown(untilHittable: app.match(A11y.annualChart))
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
		// app opens straight into a detail view a few months ahead.
		app.terminate()
		app.launchEnvironment[ScreenshotLaunch.timeOffsetDaysKey] = String(ScreenshotFixtures.timeTravelOffsetDays)
		app.launch()
		let travelledDetail = app.match(A11y.detailScreen)
		XCTAssertTrue(travelledDetail.waitForExistence(timeout: 30), "Travelled detail view never appeared")
		try await settle()
		capture(app, named: "04-time-travel")
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
}
