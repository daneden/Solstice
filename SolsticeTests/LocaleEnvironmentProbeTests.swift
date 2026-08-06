//
//  LocaleEnvironmentProbeTests.swift
//  SolsticeTests
//
//  Answers one question for the screenshot pipeline: can a single process render
//  every locale by overriding `\.locale`, instead of relaunching the app per
//  language? Relaunching is what makes the visionOS capture take two hours.
//
//  The catch is that SwiftUI and Foundation disagree about where "the locale"
//  comes from. `Text(LocalizedStringKey)` resolves against the environment;
//  `Duration.formatted(...)` returns a String built from `Locale.current`, the
//  process locale, and no environment override can reach it.
//
//  Rendering both under two locales and comparing PNG bytes settles it without
//  reading a word of text: different bytes mean the locale took effect.
//

@testable import Solstice
import SwiftUI
import XCTest

@MainActor
final class LocaleEnvironmentProbeTests: XCTestCase {
	private func png(_ view: some View) -> Data? {
		let renderer = ImageRenderer(content: view.frame(width: 420, height: 80).background(.white))
		renderer.scale = 1
		#if os(macOS)
			return renderer.nsImage?.pngData()
		#else
			return renderer.uiImage?.pngData()
		#endif
	}

	/// The load-bearing case. If a catalog string follows the environment, one
	/// process can render every language.
	func testCatalogStringFollowsEnvironmentLocale() throws {
		let en = try XCTUnwrap(png(Text("Total daylight").environment(\.locale, Locale(identifier: "en"))))
		let ja = try XCTUnwrap(png(Text("Total daylight").environment(\.locale, Locale(identifier: "ja"))))
		let de = try XCTUnwrap(png(Text("Total daylight").environment(\.locale, Locale(identifier: "de"))))

		XCTAssertNotEqual(en, ja, "Text(LocalizedStringKey) did not follow the environment locale (en vs ja)")
		XCTAssertNotEqual(en, de, "Text(LocalizedStringKey) did not follow the environment locale (en vs de)")
	}

	/// `Text(_, format:)` is the form MarketingWidgetRenderer relies on.
	func testTextWithFormatFollowsEnvironmentLocale() throws {
		let duration = Duration.seconds(53640)
		func render(_ id: String) -> Data? {
			png(Text(duration, format: .units(allowed: [.hours, .minutes], width: .wide))
				.environment(\.locale, Locale(identifier: id)))
		}
		let en = try XCTUnwrap(render("en"))
		let ja = try XCTUnwrap(render("ja"))
		XCTAssertNotEqual(en, ja, "Text(_, format:) did not follow the environment locale")
	}

	/// The other side of the boundary: the app has 10 of these, several in the
	/// hero shot's headline. If this passes as "equal", they stay in the launch
	/// language no matter what the environment says — and the screenshot looks
	/// plausible while being wrong.
	func testStringBasedFormattedIgnoresEnvironmentLocale() throws {
		let duration = Duration.seconds(53640)
		func render(_ id: String) -> Data? {
			// Exactly the shape used in NTSolar++.swift and TimeInterval++.swift.
			let s = duration.formatted(.units(maximumUnitCount: 2))
			return png(Text(verbatim: s).environment(\.locale, Locale(identifier: id)))
		}
		let en = try XCTUnwrap(render("en"))
		let ja = try XCTUnwrap(render("ja"))
		XCTAssertEqual(en, ja, "String-based .formatted() followed the environment locale — the constraint may have lifted")
	}

	/// And the fix, if we go that way: the same call with an explicit locale.
	func testStringBasedFormattedRespectsExplicitLocale() {
		let duration = Duration.seconds(53640)
		let en = duration.formatted(.units(maximumUnitCount: 2).locale(Locale(identifier: "en")))
		let ja = duration.formatted(.units(maximumUnitCount: 2).locale(Locale(identifier: "ja")))
		XCTAssertNotEqual(en, ja, "explicit .locale() on the format style had no effect")
	}
}
