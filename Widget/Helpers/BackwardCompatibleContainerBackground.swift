//
//  BackwardCompatibleContainerBackground.swift
//  Solstice
//
//  Created by Daniel Eden on 20/09/2023.
//

import SwiftUI

struct BackwardCompatibleContainerBackground<Style: ShapeStyle>: ViewModifier {
	var style: Style
	func body(content: Content) -> some View {
		if #available(iOS 17, macOS 14, watchOS 10, *) {
			content
				.containerBackground(style, for: .widget)
		} else {
			content
				.background(style)
		}
	}
}

extension View {
	func backwardCompatibleContainerBackground(_ style: some ShapeStyle) -> some View {
		self.modifier(BackwardCompatibleContainerBackground(style: style))
	}
}
