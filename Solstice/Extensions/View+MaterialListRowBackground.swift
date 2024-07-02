//
//  View+MaterialListRowBackground.swift
//  Solstice
//
//  Created by Dan Eden on 01/07/2024.
//

import SwiftUI

struct MateriaListRowBackground: ViewModifier {
	func body(content: Content) -> some View {
		content
			#if os(watchOS)
			.modify { content in
				if #available(watchOS 10, *) {
					content
						.listRowBackground(
							Color.clear.background(
								.ultraThinMaterial,
								in: RoundedRectangle(cornerRadius: 12)
							)
						)
				} else {
					content
						.listRowBackground(
							Color.clear.background(
								.background,
								in: RoundedRectangle(cornerRadius: 12)
							)
						)
				}
			}
			#endif
	}
}

extension View {
	func materialListRowBackground() -> some View {
		return self.modifier(MateriaListRowBackground())
	}
}
