//
//  View+MaterialListRowBackground.swift
//  Solstice
//
//  Created by Dan Eden on 01/07/2024.
//

import Suite
import SwiftUI

struct MateriaListRowBackground: ViewModifier {
	func body(content: Content) -> some View {
		content
		#if os(watchOS)
		.listRowBackground(
			Color.clear.background(
				.ultraThinMaterial,
				in: RoundedRectangle(cornerRadius: 12)
			)
		)
		#endif
	}
}

extension View {
	func materialListRowBackground() -> some View {
		return modifier(MateriaListRowBackground())
	}
}
