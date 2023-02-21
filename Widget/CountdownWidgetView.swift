//
//  CountdownWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 21/02/2023.
//

import SwiftUI
import Solar
import WidgetKit

struct CountdownWidgetView: View {
	@Environment(\.widgetFamily) var family
	@Environment(\.sizeCategory) var sizeCategory
	var solar: Solar
	var nextSunEvent: Solar.Event?
	
	var displaySize: Font {
		switch family {
		case .systemSmall:
			return sizeCategory < .extraLarge ? .headline : .footnote
		default:
			return .title2
		}
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			if let nextSunEvent {
				Image(systemName: currentEventImageName)
					.font(displaySize)
				
				Spacer(minLength: 0)
				
				HStack {
					Text("\(nextSunEvent.description.localizedCapitalized) \(nextSunEvent.date.formatted(.relative(presentation: .numeric)))")
						.font(displaySize.weight(.medium))
						.lineLimit(3)
						.fixedSize(horizontal: false, vertical: true)
					Spacer(minLength: 0)
				}
				
				Label("\(nextSunEvent.date, style: .time)", systemImage: nextSunEvent.imageName)
					.font(.footnote.weight(.semibold))
			} else {
				Text("Error")
			}
		}
		.padding()
		.shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .center))
		.background(LinearGradient(colors: SkyGradient.getCurrentPalette(for: solar), startPoint: .top, endPoint: .bottom))
		.colorScheme(.dark)
		.symbolRenderingMode(.hierarchical)
		.symbolVariant(.fill)
	}
	
	var currentEventImageName: String {
		return "moon.stars"
//		switch nextSunEvent {
//		case .sunrise(_):
//			return "moon.stars"
//		case .sunset(_):
//			return "sun.max"
//		}
	}
}
