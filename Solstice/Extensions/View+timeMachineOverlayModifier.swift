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
	
	func body(content: Content) -> some View {
		content
		#if os(visionOS)
			.ornament(attachmentAnchor: .scene(.bottomTrailing), contentAlignment: .trailing) {
				TimeMachineOverlayView()
			}
		#else
			.floatingOverlay(alignment: .bottom) {
				switch horizontalSizeClass {
				case .regular:
					TimeMachineDraggableOverlayView()
				default:
					TimeMachineOverlayView()
						#if os(iOS)
						.background {
							VariableBlurView(maxBlurRadius: 10, direction: .blurredBottomClearTop)
								.ignoresSafeArea(.container, edges: .bottom)
						}
						#endif
				}
			}
		#endif
	}
}

extension View {
	func timeMachineOverlay() -> some View {
		modifier(TimeMachineOverlayModifier())
	}
}
