//
//  MarketingWidgetRenderer.swift
//  Solstice
//
//  Created by Daniel Eden on 16/07/2026.
//

#if DEBUG
	import CoreLocation
	import SwiftUI

	/// Renders the app's widgets to PNGs for the macOS App Store marketing frame.
	/// macOS widgets can't be driven by the `open`+`screencapture` app pipeline, so
	/// we render faithful copies of the widget bodies off-device with `ImageRenderer`.
	/// DEBUG-only — never ships. Mirrors `OverviewWidgetView.RectangularView` and
	/// `CountdownWidgetView` (which live in the widget-extension targets and aren't
	/// reachable from here); keep in sync if those layouts change.
	enum MarketingWidgetRenderer {
		/// London — the widgets' default marketing location.
		private static let coordinate = CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276)
		private static let timeZone = TimeZone(identifier: "Europe/London")!

		/// Today at 18:45 local. The widget compares daylight against *yesterday* and
		/// counts down to the next event only when the entry is "today" (otherwise both
		/// fall back to wall-clock `Date()`), so we render for today — which is also what
		/// a user actually sees — at an evening time that leaves a short sunset countdown.
		private static let date: Date = {
			var calendar = Calendar(identifier: .gregorian)
			calendar.timeZone = timeZone
			let today = calendar.dateComponents([.year, .month, .day], from: Date())
			var components = DateComponents()
			components.year = today.year
			components.month = today.month
			components.day = today.day
			components.hour = 18
			components.minute = 45
			components.timeZone = timeZone
			return calendar.date(from: components) ?? Date()
		}()

		/// macOS point sizes: large is portrait, medium is landscape ~2:1.
		private static let largeSize = CGSize(width: 338, height: 354)
		private static let mediumSize = CGSize(width: 338, height: 158)

		enum RenderError: Error { case noSolar, encodingFailed }

		/// The rendered widget PNGs, named for their output files. Returning `Data`
		/// lets the test attach them to the `.xcresult` (an iOS-Simulator test can't
		/// write into the repo because of the app sandbox).
		/// Renders in the CURRENT process locale — run under the `Screenshots` test plan,
		/// each configuration's language drives both number/unit formatting and RTL, so no
		/// `.environment(\.locale)`/`.layoutDirection` override is needed. Attachment names
		/// carry no locale suffix; the extractor keys locale by the test-plan configuration.
		@MainActor
		static func pngs() throws -> [(name: String, data: Data)] {
			guard let solar = NTSolar(for: date, coordinate: coordinate, timeZone: timeZone) else {
				throw RenderError.noSolar
			}
			// ImageRenderer renders in isolation and does NOT inherit the process
			// layoutDirection (real windows do), so derive RTL from the current locale
			// explicitly. The locale itself IS inherited, so Text still localizes.
			let layout: LayoutDirection = Locale.current.language.characterDirection == .rightToLeft
				? .rightToLeft : .leftToRight
			func framed(_ view: some View, _ size: CGSize) -> some View {
				view
					.environment(\.layoutDirection, layout)
					.frame(width: size.width, height: size.height)
					.clipShape(.rect(cornerRadius: 30, style: .continuous))
			}
			let overview = framed(OverviewMarketingWidget(solar: solar, timeZone: timeZone), largeSize)
			let countdown = framed(CountdownMarketingWidget(solar: solar, timeZone: timeZone, referenceDate: date), mediumSize)
			return try [
				(name: "mac-04-widget-overview", data: pngData(overview)),
				(name: "mac-04-widget-countdown", data: pngData(countdown)),
			]
		}

		/// Writes the PNGs into `directory` — used when the caller can reach the FS.
		@MainActor
		static func render(to directory: URL) throws {
			try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
			for png in try pngs() {
				try png.data.write(to: directory.appendingPathComponent("\(png.name).png"))
			}
		}

		@MainActor
		private static func pngData(_ view: some View) throws -> Data {
			let renderer = ImageRenderer(content: view)
			renderer.scale = 3
			renderer.isOpaque = false

			#if os(macOS)
				guard let data = renderer.nsImage?.pngData() else { throw RenderError.encodingFailed }
			#else
				guard let data = renderer.uiImage?.pngData() else { throw RenderError.encodingFailed }
			#endif
			return data
		}
	}

	// MARK: - Reconstructed widget bodies

	private struct MarketingLocationLabel: View {
		var body: some View {
			HStack(spacing: 4) {
				Text(verbatim: "London")
				Image(systemName: "location")
					.imageScale(.small)
					.symbolVariant(.fill)
			}
			.font(.footnote.weight(.semibold))
		}
	}

	/// Mirrors `OverviewWidgetView.RectangularView` at `.systemLarge`.
	private struct OverviewMarketingWidget: View {
		let solar: NTSolar
		let timeZone: TimeZone

		var body: some View {
			ZStack(alignment: .bottomLeading) {
				GeometryReader { _ in
					DaylightChart(
						solar: solar,
						timeZone: timeZone,
						showEventTypes: false,
						includesSummaryTitle: false,
						hideXAxis: true,
						markSize: 5
					)
					.frame(maxHeight: 250)
					// systemLarge shows the full arc (medium/small fade it with a radial mask).
					.mask { Color.black }
				}
				// Bleed horizontally, but inset the top so the arc peak isn't crammed
				// against the widget's top edge.
				.padding(.horizontal, -20)
				.padding(.top, 32)

				VStack(alignment: .leading, spacing: 4) {
					MarketingLocationLabel()
						.foregroundStyle(.secondary)

					Spacer()

					Text("Daylight today")
						.font(.footnote)

					// Text(_:format:) resolves against the environment locale (unlike the
					// app's String-based `.localizedString`, which uses the process locale),
					// so the units localize in the per-locale render.
					Text(Duration.seconds(solar.daylightDuration), format: .units(allowed: [.hours, .minutes], width: .abbreviated))
						.font(.title3).fontWeight(.semibold).fontDesign(.rounded)
						.lineLimit(4)
						.fixedSize(horizontal: false, vertical: true)

					differenceText
						.font(.footnote)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.fixedSize(horizontal: false, vertical: true)

					HStack {
						Label { Text(solar.safeSunrise, style: .time) } icon: { Image(systemName: "sunrise.fill") }
						Spacer()
						Label { Text(solar.safeSunset, style: .time) } icon: { Image(systemName: "sunset.fill") }
					}
					.font(.footnote.weight(.semibold))
				}
				.padding(20)
				.symbolRenderingMode(.hierarchical)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			.environment(\.timeZone, timeZone)
			.background(.background)
		}

		/// Mirrors `compactDifferenceString` but as a `Text(_:format:)` so the units
		/// localize against the environment locale.
		private var differenceText: Text {
			guard let yesterday = solar.yesterday else { return Text(verbatim: "") }
			let diff = solar.daylightDuration - yesterday.daylightDuration
			let magnitude = Text(Duration.seconds(abs(diff)), format: .units(allowed: [.hours, .minutes], width: .abbreviated))
			let sign = diff >= 0 ? "+" : "-"
			return Text("\(sign)\(magnitude)")
		}
	}

	/// Mirrors `CountdownWidgetView` at `.systemMedium` (SkyGradient container background).
	private struct CountdownMarketingWidget: View {
		let solar: NTSolar
		let timeZone: TimeZone
		/// The countdown is relative to this fixed date (not `.now`), so the render is
		/// deterministic — `Text(_, style: .relative)` would resolve against wall-clock time.
		let referenceDate: Date

		var body: some View {
			VStack(alignment: .leading, spacing: 4) {
				MarketingLocationLabel()

				Spacer(minLength: 0)

				HStack {
					nextEventText
						.font(.title3).fontWeight(.semibold).fontDesign(.rounded)
						.minimumScaleFactor(0.8)
						.lineLimit(3)
					Spacer()
				}

				if let next = solar.nextSolarEvent {
					Label { Text(next.date, style: .time) } icon: { Image(systemName: next.imageName) }
						.font(.footnote.weight(.semibold))
				}
			}
			.padding(20)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			.foregroundStyle(.white)
			.symbolRenderingMode(.hierarchical)
			.symbolVariant(.fill)
			.environment(\.timeZone, timeZone)
			.background { SkyGradient(ntSolar: solar) }
			.preferredColorScheme(.dark)
		}

		private var nextEventText: Text {
			guard let next = solar.nextSolarEvent else { return Text(verbatim: "—") }
			// Both the event name (a localized string resource) and the remaining
			// duration localize against the environment locale, matching the real widget.
			let remaining = Text(
				Duration.seconds(max(0, next.date.timeIntervalSince(referenceDate))),
				format: .units(allowed: [.hours, .minutes], width: .abbreviated)
			)
			return Text("\(Text(next.label)) in \(remaining)")
		}
	}
#endif
