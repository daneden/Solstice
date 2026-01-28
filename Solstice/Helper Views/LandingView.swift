//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 14/08/2025.
//

import SwiftUI
import Solar
import Suite

fileprivate struct SizePreferenceKey: PreferenceKey {
	static let defaultValue: Double = 0
	
	static func reduce(value: inout Double, nextValue: () -> Double) {
		value = nextValue()
	}
}

fileprivate extension View {
	func animateIn(active: Bool, delay: TimeInterval, speed: Double = 0.6) -> some View {
		self
			.opacity(active ? 1 : 0)
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
	@AppStorage(Preferences.hasCompletedOnboarding) private var hasCompletedOnboarding
	@State private var animate = false
	
	@State private var contentSize: CGSize = CGSize(width: 0, height: 200)
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
	
	@State private var solar = Solar(coordinate: .proxiedToTimeZone)
	private let renderTime = Date.now
	
    var body: some View {
			ZStack {
				TimelineView(.animation) { context in
					SkyGradient(solar: solar)
						.ignoresSafeArea()
						.task(id: context.date) {
							solar = Solar(
								for: renderTime.addingTimeInterval(context.date.distance(to: renderTime) * 1000),
								coordinate: .proxiedToTimeZone
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
			.onDisappear {
				hasCompletedOnboarding = true
			}
			.preference(key: SizePreferenceKey.self, value: contentSize.height + bottomButtonSize.height)
    }
}

#Preview {
    LandingView()
}

fileprivate struct WithOnboardingViewModifier: ViewModifier {
	@AppStorage(Preferences.hasCompletedOnboarding) private var hasCompletedOnboarding
	@Environment(CurrentLocation.self) private var currentLocation
	
	@State private var shouldPresentOnboarding = false
	
	@State private var sheetSize: Double = 0
	
	func body(content: Content) -> some View {
		content
			.task {
				shouldPresentOnboarding = !currentLocation.isAuthorized && !hasCompletedOnboarding
			}
			.sheet(isPresented: $shouldPresentOnboarding) {
				LandingView()
					.onPreferenceChange(SizePreferenceKey.self, perform: { size in
						sheetSize = size
					})
					.presentationDetents([.height(sheetSize)])
					.interactiveDismissDisabled()
			}
	}
}

extension View {
	func withAppOnboarding() -> some View {
		self.modifier(WithOnboardingViewModifier())
	}
}
