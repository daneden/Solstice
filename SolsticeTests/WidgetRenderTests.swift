//
//  WidgetRenderTests.swift
//  SolsticeTests
//
//  Renders the macOS marketing widgets (Frame 4) in the CURRENT process locale and
//  attaches them to the .xcresult. Run under the `Screenshots` test plan, this fires
//  once per locale configuration (in that config's language, incl. RTL), and the
//  `capture-screenshots.sh` extractor keys the locale by configurationName — exactly
//  like the iOS shots. Drives `MarketingWidgetRenderer` (app target, DEBUG) so the
//  heavy SwiftUI/Solar types stay in the app and this target needs only @testable import.
//

@testable import Solstice
import XCTest

@MainActor
final class WidgetRenderTests: XCTestCase {
	func testRenderMarketingWidgets() throws {
		for png in try MarketingWidgetRenderer.pngs() {
			let attachment = XCTAttachment(data: png.data, uniformTypeIdentifier: "public.png")
			attachment.name = "\(png.name).png"
			attachment.lifetime = .keepAlways
			add(attachment)
		}
	}
}
