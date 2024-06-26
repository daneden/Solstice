//
//  BackwardCompatibleContainerBackground.swift
//  Solstice
//
//  Created by Daniel Eden on 20/09/2023.
//

import SwiftUI

struct BackwardCompatibleContainerBackground<Background: View>: ViewModifier {
	@ViewBuilder
	var style: () -> Background
	
	func body(content: Content) -> some View {
		if #available(iOS 17, macOS 14, watchOS 10, *) {
			content
				.containerBackground(for: .widget) {
					style()
				}
		} else {
			content
				.background { style() }
		}
	}
}

extension View {
	func backwardCompatibleContainerBackground(style: @escaping () -> some View) -> some View {
		self.modifier(BackwardCompatibleContainerBackground(style: style))
	}
}
