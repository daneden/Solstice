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
					.font(.footnote)
					.widgetAccentable()
					.contentTransition(.numericText())
					
					DaylightChart(
						solar: solar,
						timeZone: location.timeZone,
						eventTypes: [],
						includesSummaryTitle: false,
						markSize: 3
					)
					.padding(.top, 4)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else {
				WidgetMissingLocationView()
			}
		}
		.containerBackground(.background, for: .widget)
	}
}

#if !os(macOS)
#Preview(as: WidgetFamily.accessoryRectangular) {
	SolarChartWidget()
} timeline: {
	SolsticeWidgetTimelineEntry(date: .now, location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 6), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 12), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 18), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 24), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 30), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36), location: .defaultLocation)
}
#endif

#if !os(watchOS)
#Preview(as: WidgetFamily.systemSmall) {
	SolarChartWidget()
} timeline: {
	SolsticeWidgetTimelineEntry(date: .now, location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 6), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 12), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 18), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 24), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 30), location: .defaultLocation)
	SolsticeWidgetTimelineEntry(date: .now.addingTimeInterval(60 * 60 * 36), location: .defaultLocation)
}
#endif
