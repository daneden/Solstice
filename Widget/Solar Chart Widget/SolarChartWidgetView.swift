//
//  SolarChartWidgetView.swift
//  Solstice
//
//  Created by Daniel Eden on 12/04/2023.
//

import SwiftUI
import WidgetKit
import Solar

struct SolarChartWidgetView: View {
	var entry: SolsticeWidgetTimelineEntry
	
	var solar: Solar? {
		guard let location else { return nil }
		return Solar(for: entry.date, coordinate: location.coordinate)
	}
	
	var location: SolsticeWidgetLocation? {
		entry.location
	}
	
	var body: some View {
		Group {
			if let solar,
				 let location {
				ZStack(alignment: .topLeading) {
					HStack {
						Label {
							Text(solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone), style: .time)
						} icon: {
							Image(systemName: "sunrise")
						}
						.labelStyle(CompactLabelStyle())
						
						Spacer()
						
						Label {
							Text(solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone), style: .time)
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
						solar: solar,
						timeZone: location.timeZone,
						showEventTypes: false,
						includesSummaryTitle: false,
						markSize: 3,
						yScale: -1.0...1.5
					)
				}
			} else {
				WidgetMissingLocationView()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.backwardCompatibleContainerBackground {
			Color.clear.background(.background)
		}
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
