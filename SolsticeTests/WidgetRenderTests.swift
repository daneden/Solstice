//
//  WidgetRenderTests.swift
//  SolsticeTests
//
//  Renders the macOS marketing widgets (Frame 4) for every shipping locale and
//  attaches them to the .xcresult, from which the compose step extracts the PNGs.
//  Not a behavioural test — it drives `MarketingWidgetRenderer` (app target, DEBUG)
//  so the heavy SwiftUI/Solar types stay in the app and this target needs only
//  @testable import. Attachments are named "widget-<kind>__<locale>.png".
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
	private let locales = ["en", "de", "fr", "es", "ja", "ar", "nl", "zh-Hans", "pl", "it"]

	func testRenderMarketingWidgets() throws {
		for locale in locales {
			for png in try MarketingWidgetRenderer.pngs(for: locale) {
				let attachment = XCTAttachment(data: png.data, uniformTypeIdentifier: "public.png")
				attachment.name = "\(png.name)__\(locale).png"
				attachment.lifetime = .keepAlways
				add(attachment)
			}
		}
	}
}
