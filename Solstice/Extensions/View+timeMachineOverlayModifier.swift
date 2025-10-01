//
//  View+timeMachineOverlayModifier.swift
//  Solstice
//
//  Created by Daniel Eden on 20/05/2025.
//

import SwiftUI
import Suite

struct TimeMachineOverlayModifier: ViewModifier {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@AppStorage(Preferences.timeTravelAppearance) private var timeMachineAppearance
	@State private var size = CGSize.zero
	
	func body(content: Content) -> some View {
		content
		#if os(visionOS)
			.ornament(attachmentAnchor: .scene(.bottomTrailing), contentAlignment: .trailing) {
				TimeMachinePanelView()
			}
		#else
			.modify { content in
				if #available(iOS 26, macOS 26, *) {
					content
						.contentMargins(.bottom, size.height, for: .automatic)
						.safeAreaBar(edge: .bottom) {
							overlay
								.readSize($size)
						}
				} else {
					content
						.backportSafeAreaBar {
							overlay
#if os(iOS)
								.background {
									if #unavailable(iOS 26) {
										VariableBlurView(maxBlurRadius: 1, direction: .blurredBottomClearTop)
											.background {
												Color.clear
													.background(.background)
													.mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
											}
											.ignoresSafeArea()
									}
								}
#endif
						}
				}
			}
			.animation(.default, value: timeMachineAppearance)
		#endif
	}
	
	@ViewBuilder var overlay: some View {
		switch horizontalSizeClass {
		case .regular:
			TimeMachineDraggableOverlayView()
		default:
			switch timeMachineAppearance {
			case .compact:
				TimeTravelCompactView()
					.transition(.blurReplace)
			default:
				TimeMachinePanelView()
					.transition(.blurReplace)
			}
		}
	}
}

extension View {
	func timeMachineOverlay() -> some View {
		modifier(TimeMachineOverlayModifier())
	}
}
