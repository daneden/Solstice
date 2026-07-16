//
//  WidgetRenderTests.swift
//  SolsticeTests
//
//  Renders the macOS marketing widgets (Frame 4) and attaches them to the
//  .xcresult, from which the compose step extracts the PNGs. Not a behavioural
//  test — it drives `MarketingWidgetRenderer` (app target, DEBUG) so the heavy
//  SwiftUI/Solar types stay in the app and this target needs only @testable import.
//
//  Run + extract:
//    xcodebuild test -scheme Solstice -only-testing:SolsticeTests/WidgetRenderTests \
//      -destination 'platform=iOS Simulator,name=iPhone 17' -resultBundlePath <bundle>
//    xcrun xcresulttool export attachments --path <bundle> --output-path <dir>
//

@testable import Solstice
import XCTest

@MainActor
final class WidgetRenderTests: XCTestCase {
	func testRenderMarketingWidgets() throws {
		let pngs = try MarketingWidgetRenderer.pngs()
		XCTAssertEqual(pngs.count, 2)

		for png in pngs {
			let attachment = XCTAttachment(data: png.data, uniformTypeIdentifier: "public.png")
			attachment.name = "\(png.name).png"
			attachment.lifetime = .keepAlways
			add(attachment)
		}
	}
}
