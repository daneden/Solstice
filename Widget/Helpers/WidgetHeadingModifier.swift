//
//  WidgetHeadingModifier.swift
//  Solstice
//
//  Created by Daniel Eden on 04/04/2023.
//

import SwiftUI
import WidgetKit

struct WidgetHeadingModifier: ViewModifier {
	@Environment(\.widgetFamily) var family
	@Environment(\.dynamicTypeSize) var sizeCategory
	
	var displaySize: Font {
		switch family {
		case .systemSmall:
			return sizeCategory < .xLarge ? .headline : .footnote
		default:
			return .title3
		}
	}
	
	func body(content: Content) -> some View {
		content
			.font(displaySize)
			.fontWeight(.semibold)
			.fontDesign(.rounded)
	}
}

extension View {
	func widgetHeading() -> some View {
		self.modifier(WidgetHeadingModifier())
	}
}
