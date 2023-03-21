//
//  View+EllipticalEdgeMask.swift
//  Solstice watchOS Watch App
//
//  Created by Daniel Eden on 01/03/2023.
//

import SwiftUI

struct EllipticalEdgeMaskModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.mask(
				EllipticalGradient(
					gradient: Gradient(stops: [
						Gradient.Stop(color: .black, location: 0.9),
						Gradient.Stop(color: .clear, location: 1.0)
					])
				)
			)
	}
}

extension View {
	func ellipticalEdgeMask() -> some View {
		self.modifier(EllipticalEdgeMaskModifier())
	}
}
