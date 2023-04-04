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
	var location: SolsticeWidgetLocation
	
	var body: some View {
		if let nextSolarEvent,
			 let previousSolarEvent {
			switch family {
			#if !os(macOS)
			case .accessoryCircular:
				AccessoryCircularView(previousEvent: previousSolarEvent, nextEvent: nextSolarEvent)
			case .accessoryInline:
				AccessoryInlineView(nextEvent: nextSolarEvent)
			case .accessoryRectangular:
				AccessoryRectangularView(nextEvent: nextSolarEvent)
			#if os(watchOS)
			case .accessoryCorner:
				AccessoryCornerView(nextEvent: nextSolarEvent)
			#endif // end watchOS
			#endif // end !macOS
			default:
				VStack(alignment: .leading, spacing: 4) {
					WidgetLocationView(location: location)
					
					Spacer(minLength: 0)
					
					HStack {
						nextEventText
							.widgetHeading()
							.minimumScaleFactor(0.8)
							.lineLimit(3)
						
						Spacer()
					}
					
					Label("\(nextSolarEvent.date.withTimeZoneAdjustment(for: timeZone), style: .time)", systemImage: nextSolarEvent.imageName)
						.font(.footnote.weight(.semibold))
						.imageScale(.small)
				}
				.padding()
				.shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.background(
					LinearGradient(
						colors: [.black.opacity(0.15), .clear],
						startPoint: .bottom,
						endPoint: .center
					).blendMode(.plusDarker)
				)
				.background(
					LinearGradient(
						colors: SkyGradient.getCurrentPalette(for: solar),
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.foregroundStyle(.white)
				.symbolRenderingMode(.hierarchical)
				.symbolVariant(.fill)
			}
		}
	}
}

extension CountdownWidgetView {
	var nextSolarEvent: Solar.Event? {
		solar.nextSolarEvent
	}
	
	var previousSolarEvent: Solar.Event? {
		solar.previousSolarEvent
	}
	
	var timeZone: TimeZone {
		location.timeZone
	}
	
	var nextEventText: some View {
		if let nextSolarEvent {
			return Text("\(nextSolarEvent.description.localizedCapitalized) in \(Text(nextSolarEvent.date, style: .relative))")
		} else {
			return Text("—")
		}
	}
	
	var currentEventImageName: String {
		nextSolarEvent?.phase == .sunrise ? "moon.stars" : "sun.max"
	}
}

struct CountdownWigetView_Previews: PreviewProvider {
	static var previews: some View {
		CountdownWidgetView(solar: Solar(coordinate: .init())!, location: .defaultLocation)
		#if os(watchOS)
			.previewContext(WidgetPreviewContext(family: .accessoryCircular))
		#else
			.previewContext(WidgetPreviewContext(family: .systemSmall))
		#endif
	}
}
