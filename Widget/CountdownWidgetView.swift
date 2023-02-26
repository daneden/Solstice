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
	var location: SolsticeWidgetLocation
	
	var timeZone: TimeZone {
		location.timeZone
	}
	
	var displaySize: Font {
		switch family {
		case .systemSmall:
			return sizeCategory < .extraLarge ? .headline : .footnote
		default:
			return .title2
		}
	}
	
	var nextEventText: some View {
		if let nextSolarEvent {
			return Text("\(nextSolarEvent.description.localizedCapitalized) \(nextSolarEvent.date.formatted(.relative(presentation: .numeric)))")
		} else {
			return Text("Loading...")
		}
	}
	
	var body: some View {
		if let nextSolarEvent {
			switch family {
			case .accessoryInline:
				HStack {
					Image(systemName: nextSolarEvent.imageName)
					nextEventText
				}
			case .accessoryRectangular:
				Label("\(nextSolarEvent.date.withTimeZoneAdjustment(for: timeZone), style: .time)", systemImage: nextSolarEvent.imageName)
			default:
				VStack(alignment: .leading, spacing: 8) {
					WidgetLocationView(location: location)
					
					Spacer(minLength: 0)
					
					HStack {
						nextEventText
							.font(displaySize.weight(.medium))
							.lineLimit(3)
						
						Spacer(minLength: 0)
					}
					
					Label("\(nextSolarEvent.date.withTimeZoneAdjustment(for: timeZone), style: .time)", systemImage: nextSolarEvent.imageName)
						.font(.footnote.weight(.semibold))
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
		}
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
		CountdownWidgetView(solar: Solar(coordinate: .init())!, location: .defaultLocation)
			.previewContext(WidgetPreviewContext(family: .systemSmall))
	}
}