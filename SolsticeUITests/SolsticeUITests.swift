//
//  SolsticeUITests.swift
//  SolsticeUITests
//
//  UI tests for visual regression detection
//

import XCTest

final class SolsticeUITests: XCTestCase {

	let app = XCUIApplication()

	override func setUpWithError() throws {
		continueAfterFailure = false
		app.launch()
	}

	// MARK: - App Launch & Basic Structure

	func testAppLaunches() throws {
		// Verify the app launches and displays its main content
		XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
	}

	// MARK: - Accent Color Regression Test
	//
	// This test guards against the regression fixed in commit 8a6fe6f where
	// the accent color broke when both scenePhase and backgroundTask modifiers
	// were present in the App struct. The symptom was that the accent color
	// would revert to the system default blue instead of the custom cyan defined
	// in AccentColor.colorset.
	//
	// We verify this by taking a screenshot on launch and attaching it to the
	// test results for visual review in Xcode Cloud. This enables reviewers to
	// spot accent color regressions in CI screenshots.

	func testAccentColorScreenshot() throws {
		// Wait for the app to fully render
		let mainContent = app.windows.firstMatch
		XCTAssertTrue(mainContent.waitForExistence(timeout: 10))

		// Allow animations and layout to settle
		sleep(2)

		// Capture a screenshot and attach it to the test results.
		// In Xcode Cloud, these attachments are available in the test report,
		// allowing visual verification that the accent color is correct.
		let screenshot = app.screenshot()
		let attachment = XCTAttachment(screenshot: screenshot)
		attachment.name = "App Launch - Accent Color Check"
		attachment.lifetime = .keepAlways
		add(attachment)
	}

	// MARK: - Navigation Structure

	func testMainViewHasContent() throws {
		// Verify that the app renders meaningful content after launch.
		// This catches crashes or blank screens caused by modifier conflicts.
		let mainWindow = app.windows.firstMatch
		XCTAssertTrue(mainWindow.waitForExistence(timeout: 10))

		// The app should have at least some static text visible
		let hasVisibleText = app.staticTexts.firstMatch.waitForExistence(timeout: 10)
		XCTAssertTrue(hasVisibleText, "App should display text content after launch")
	}
}
