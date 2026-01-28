//
//  SolarChartWidgetView.swift
//  Solstice
//
//  Created by Daniel Eden on 12/04/2023.
//

import SwiftUI
import WidgetKit
import SunKit

struct SolarChartWidgetView: SolsticeWidgetView {
	var entry: SolsticeWidgetTimelineEntry
	
	var body: some View {
		Group {
			if let sun,
				 let location {
				ZStack(alignment: .topLeading) {
					HStack {
						Label {
							Text(sun.safeSunrise.withTimeZoneAdjustment(for: location.timeZone), style: .time)
						} icon: {
							Image(systemName: "sunrise")
						}
						.labelStyle(CompactLabelStyle())

						Spacer()

						Label {
							Text(sun.safeSunset.withTimeZoneAdjustment(for: location.timeZone), style: .time)
						} icon: {
							Image(systemName: "sunset")
						}
						.labelStyle(CompactLabelStyle(reverseOrder: true))
					}
					.symbolVariant(.fill)
					.imageScale(.small)
					.font(.caption)
					.widgetAccentable()
					.contentTransition(.numericText())

					DaylightChart(
						sun: sun,
						timeZone: location.timeZone,
						showEventTypes: false,
						includesSummaryTitle: false,
						markSize: 3,
						yScale: -1.0...1.5
					)
				}
			} else if shouldShowPlaceholder {
				SolarChartWidgetView(entry: .placeholder)
					.redacted(reason: .placeholder)
			} else {
				WidgetMissingLocationView()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.containerBackground(.background, for: .widget)
	}
}

#if !os(macOS)
struct SolarChartWidgetPreview: PreviewProvider {
	static var previews: some View {
		SolarChartWidgetView(entry: SolsticeWidgetTimelineEntry(date: .now))
			.previewContext(WidgetPreviewContext(family: .accessoryRectangular))
	}
}
#endif
