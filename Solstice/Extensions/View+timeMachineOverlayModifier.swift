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
	@State private var size = CGSize.zero
	
	func body(content: Content) -> some View {
		content
		#if os(visionOS)
			.ornament(attachmentAnchor: .scene(.bottomTrailing), contentAlignment: .trailing) {
				TimeMachineOverlayView()
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
					content.backportSafeAreaBar { overlay }
				}
			}
		#endif
	}
	
	@ViewBuilder var overlay: some View {
		switch horizontalSizeClass {
		case .regular:
			TimeMachineDraggableOverlayView()
		default:
			TimeMachineOverlayView()
		}
	}
}

extension View {
	func timeMachineOverlay() -> some View {
		modifier(TimeMachineOverlayModifier())
	}
}
