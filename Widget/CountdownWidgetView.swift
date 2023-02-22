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
	var nextSolarEvent: Solar.Event? {
		solar.nextSolarEvent
	}
	var timeZone: TimeZone
	
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
			if let nextSolarEvent {
				Image(systemName: currentEventImageName)
					.font(displaySize)
				
				Spacer(minLength: 0)
				
				HStack {
					Text("\(nextSolarEvent.description.localizedCapitalized) \(nextSolarEvent.date.formatted(.relative(presentation: .numeric)))")
						.font(displaySize.weight(.medium))
						.lineLimit(3)
						.fixedSize(horizontal: false, vertical: true)
					Spacer(minLength: 0)
				}
				
				Label("\(nextSolarEvent.date.withTimeZoneAdjustment(for: timeZone), style: .time)", systemImage: nextSolarEvent.imageName)
					.font(.footnote.weight(.semibold))
			} else {
				Text("Error")
			}
		}
		.padding()
		.shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .center).blendMode(.plusDarker))
		.background(LinearGradient(colors: SkyGradient.getCurrentPalette(for: solar), startPoint: .top, endPoint: .bottom))
		.colorScheme(.dark)
		.symbolRenderingMode(.hierarchical)
		.symbolVariant(.fill)
	}
	
	var currentEventImageName: String {
		switch nextSolarEvent?.phase {
		case .sunrise:
			return "moon.stars"
		default:
			return "sun.max"
		}
	}
}

struct CountdownWigetView_Previews: PreviewProvider {
	static var previews: some View {
		CountdownWidgetView(solar: Solar(coordinate: .init())!, timeZone: .autoupdatingCurrent)
			.previewContext(WidgetPreviewContext(family: .systemSmall))
	}
}
