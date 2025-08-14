//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 14/08/2025.
//

import SwiftUI
import Suite

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
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var currentLocation: CurrentLocation
	@AppStorage(Preferences.hasCompletedOnboarding) private var hasCompletedOnboarding
	@State private var animate = false
	
	private var isWatch: Bool {
		#if os(watchOS)
		return true
		#else
		return false
		#endif
	}
	
    var body: some View {
			ZStack {
				SkyGradient()
					.ignoresSafeArea()
				
				ScrollView {
					VStack(alignment: .leading, spacing: 8) {
						
						Text("\(Image(.solstice)) Welcome to Solstice")
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
				}
			}
			.task {
				animate = true
			}
			.floatingOverlay {
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
					}
					.glassButtonStyle(.prominent)
					.animateIn(active: animate, delay: 1.1)
					
					Button {
						dismiss()
					} label: {
						Text("Continue without location")
							.frame(maxWidth: .infinity)
					}
					.glassButtonStyle()
					.animateIn(active: animate, delay: 1.2)
				}
				.scenePadding(.horizontal)
				#if os(iOS)
				.background {
					VariableBlurView(direction: .blurredBottomClearTop)
						.ignoresSafeArea()
				}
				#endif
				.controlSize(.extraLarge)
			}
			.onDisappear {
				hasCompletedOnboarding = true
			}
    }
}

#Preview {
    LandingView()
}

fileprivate struct WithOnboardingViewModifier: ViewModifier {
	@AppStorage(Preferences.hasCompletedOnboarding) private var hasCompletedOnboarding
	@EnvironmentObject private var currentLocation: CurrentLocation
	
	@State private var shouldPresentOnboarding = false
	
	func body(content: Content) -> some View {
		content
			.task {
				shouldPresentOnboarding = !currentLocation.isAuthorized && !hasCompletedOnboarding
			}
			.sheet(isPresented: $shouldPresentOnboarding) {
				LandingView()
					.presentationDetents([.medium])
			}
	}
}

extension View {
	func withAppOnboarding() -> some View {
		self.modifier(WithOnboardingViewModifier())
	}
}
