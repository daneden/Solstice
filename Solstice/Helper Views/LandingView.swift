//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 14/08/2025.
//

import Suite
import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
	static let defaultValue: Double = 0

	static func reduce(value: inout Double, nextValue: () -> Double) {
		value = nextValue()
	}
}

private extension View {
	func animateIn(active: Bool, delay: TimeInterval, speed: Double = 0.6) -> some View {
		opacity(active ? 1 : 0)
			.blur(radius: active ? 0 : 8)
			.scaleEffect(active ? 1 : 0.8, anchor: .bottom)
			.offset(y: active ? 0 : 8)
			.animation(.bouncy.speed(speed).delay(delay), value: active)
	}
}

struct LandingView: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Environment(\.dismiss) private var dismiss
	@Environment(CurrentLocation.self) private var currentLocation
	@State private var animate = false

	@State private var contentSize: CGSize = .init(width: 0, height: 200)
	@State private var bottomButtonSize: CGSize = .zero

	private var isWatch: Bool {
		#if os(watchOS)
			return true
		#else
			return false
		#endif
	}

	@ViewBuilder
	private var bottomButtons: some View {
		VStack {
			Text("In order for Solstice to calculate the sun’s position, it needs to access your location.")
				.font(.footnote)
				.foregroundStyle(.secondary)
				.foregroundStyle(.white)
				.blendMode(.plusLighter)
				.padding(.bottom)
				.animateIn(active: animate, delay: 1)

			Button {
				currentLocation.requestAccess()
				dismiss()
			} label: {
				Label("Continue with location", systemImage: "location.fill")
					.frame(maxWidth: .infinity)
					.fontWeight(.semibold)
			}
			.glassButtonStyle(.prominent)
			.animateIn(active: animate, delay: 1.1)
		}
		.scenePadding(.horizontal)
		.scenePadding(.bottom)
		#if os(iOS)
			.background {
				VariableBlurView(direction: .blurredBottomClearTop)
					.ignoresSafeArea()
			}
		#endif
			.controlSize(.extraLarge)
			.readSize($bottomButtonSize)
	}

	private var shouldUseCompactDisplay: Bool {
		dynamicTypeSize > .accessibility2
	}

	@State private var solar = NTSolar(for: .now, coordinate: .proxiedToTimeZone, timeZone: .autoupdatingCurrent)
	private let renderTime = Date.now

	var body: some View {
		ZStack {
			TimelineView(.animation) { context in
				SkyGradient(ntSolar: solar)
					.ignoresSafeArea()
					.task(id: context.date) {
						solar = NTSolar(
							for: renderTime.addingTimeInterval(context.date.distance(to: renderTime) * 1000),
							coordinate: .proxiedToTimeZone,
							timeZone: .autoupdatingCurrent
						) ?? solar
					}
			}

			ScrollView {
				VStack(alignment: .leading, spacing: 8) {
					HStack(alignment: .firstTextBaseline) {
						Image(.solstice)
						Text("Welcome to Solstice")
					}
					.font(isWatch ? .headline : .largeTitle)
					.fontWeight(.semibold)
					.animateIn(active: animate, delay: 0.1)
					.padding(.vertical)

					Text("Solstice tells you how much daylight there is today compared to yesterday.")
						.animateIn(active: animate, delay: 0.4)
					Text("For savouring the minutes you have, or looking forward to the minutes you’ll gain.")
						.animateIn(active: animate, delay: 0.6)
				}
				.font(.title3)
				.scenePadding()
				.foregroundStyle(.white)
				.blendMode(.plusLighter)
				.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
				.readSize($contentSize)

				if shouldUseCompactDisplay {
					bottomButtons
				}
			}
		}
		.task {
			animate = true
		}
		.backportSafeAreaBar {
			if !shouldUseCompactDisplay {
				bottomButtons
			}
		}
		.preference(key: SizePreferenceKey.self, value: contentSize.height + bottomButtonSize.height)
	}
}

#Preview {
	LandingView()
}

private struct WithOnboardingViewModifier: ViewModifier {
	@Environment(CurrentLocation.self) private var currentLocation
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@State private var shouldPresentOnboarding = false

	@State private var sheetSize: Double = 0

	func body(content: Content) -> some View {
		content
			// The authorization status is the only durable record of whether the user
			// has answered; a local "seen the welcome" flag isn't. Builds before Aug
			// 2026 couldn't present the macOS prompt, so they set that flag against a
			// decision that was never made and permanently suppressed the sheet — an
			// App Group value that outlives even deleting the app on macOS. Reading
			// the status recovers those installs and can't drift from the system.
			.onChange(of: currentLocation.authorizationStatus, initial: true) { _, status in
				guard !ScreenshotLaunch.isCapturing else { return }
				shouldPresentOnboarding = status == .notDetermined
			}
			.sheet(isPresented: $shouldPresentOnboarding) {
				LandingView()
					.onPreferenceChange(SizePreferenceKey.self, perform: { size in
						sheetSize = size
					})
					.presentationDetents(horizontalSizeClass == .regular ? [.large] : [.height(sheetSize)])
			}
	}
}

extension View {
	func withAppOnboarding() -> some View {
		modifier(WithOnboardingViewModifier())
	}
}
