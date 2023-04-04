//
//  View+RectangularEdgeMask.swift
//  Solstice
//
//  Created by Daniel Eden on 04/04/2023.
//

import SwiftUI

struct RectangularEdgeMaskModifier: ViewModifier {
	private let maskGradientStops = [
		Gradient.Stop(color: .clear, location: 0),
		Gradient.Stop(color: .black, location: 0.2),
		Gradient.Stop(color: .black, location: 0.8),
		Gradient.Stop(color: .clear, location: 1.0)
	]
	func body(content: Content) -> some View {
		content
			.mask {
				LinearGradient(
					gradient: Gradient(stops: maskGradientStops),
					startPoint: .leading,
					endPoint: .trailing
				)
			}
	}
}

extension View {
	func rectangularEdgeMask() -> some View {
		self.modifier(RectangularEdgeMaskModifier())
	}
}
