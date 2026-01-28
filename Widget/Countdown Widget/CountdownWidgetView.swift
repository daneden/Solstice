//
//  CountdownWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 21/02/2023.
//

import SwiftUI
import Solar
import WidgetKit
import Suite

struct CountdownWidgetView: SolsticeWidgetView {
	@Environment(\.widgetFamily) var family
	@Environment(\.sizeCategory) var sizeCategory
	@Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground

	var entry: SolsticeWidgetTimelineEntry
	
	var body: some View {
		if let location,
			 let nextSolarEvent,
			 let previousSolarEvent {
			switch family {
			#if !os(macOS)
			case .accessoryCircular:
				AccessoryCircularView(
					entryDate: entry.date,
					previousEvent: previousSolarEvent,
					nextEvent: nextSolarEvent
				)
			case .accessoryInline:
				AccessoryInlineView(nextEvent: nextSolarEvent)
			case .accessoryRectangular:
				AccessoryRectangularView(nextEvent: nextSolarEvent)
			#if os(watchOS)
			case .accessoryCorner:
				AccessoryCornerView(previousEvent: previousSolarEvent, nextEvent: nextSolarEvent)
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
							.contentTransition(.numericText())

						Spacer()
					}

					Label{
						Text(nextSolarEvent.date.withTimeZoneAdjustment(for: timeZone), style: .time)
					} icon: {
						Image(systemName: nextSolarEvent.imageName)
					}
						.font(.footnote.weight(.semibold))
						.contentTransition(.numericText())
				}
				.if(showsWidgetContainerBackground) { content in
					content
						.shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.foregroundStyle(.white)
				.symbolRenderingMode(.hierarchical)
				.symbolVariant(.fill)
				.preferredColorScheme(.dark)
			}
		} else if shouldShowPlaceholder {
			CountdownWidgetView(entry: .placeholder)
				.redacted(reason: .placeholder)
		} else {
			WidgetMissingLocationView()
		}
	}
}

extension CountdownWidgetView {
	var nextSolarEvent: Solar.Event? {
		solar?.nextSolarEvent
	}
	
	var previousSolarEvent: Solar.Event? {
		solar?.previousSolarEvent
	}
	
	var timeZone: TimeZone {
		location?.timeZone ?? .autoupdatingCurrent
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

struct CountdownWidgetPreview: PreviewProvider {
	static var previews: some View {
		#if !os(watchOS)
		CountdownWidgetView(entry: SolsticeWidgetTimelineEntry(date: .now))
			.previewContext(WidgetPreviewContext(family: .systemSmall))
		#endif
		
		#if !os(macOS)
		CountdownWidgetView(entry: SolsticeWidgetTimelineEntry(date: .now))
			.previewContext(WidgetPreviewContext(family: .accessoryRectangular))
		#endif
	}
}
