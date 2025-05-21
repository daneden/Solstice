//
//  View+timeMachineOverlayModifier.swift
//  Solstice
//
//  Created by Daniel Eden on 20/05/2025.
//

import SwiftUI

struct TimeMachineBarHeightKey: PreferenceKey {
	typealias Value = Double
	static var defaultValue: Double = 60
	
	static func reduce(value: inout Double, nextValue: () -> Double) {
		value = nextValue()
	}
}

struct TimeMachineOverlayModifier: ViewModifier {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@State private var timeMachineBarHeight: Double = 0
	
	func body(content: Content) -> some View {
		content
			.contentMargins(.bottom, timeMachineBarHeight, for: .scrollContent)
			.overlay(alignment: .bottom) {
				switch horizontalSizeClass {
				case .regular:
					TimeMachineDraggableOverlayView()
				default:
					TimeMachineOverlayView()
				}
			}
			.onPreferenceChange(TimeMachineBarHeightKey.self) { value in
				timeMachineBarHeight = value
			}
	}
}

extension View {
	func timeMachineOverlay() -> some View {
		modifier(TimeMachineOverlayModifier())
	}
}
