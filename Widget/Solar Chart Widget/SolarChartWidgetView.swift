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
					.padding()
					
					DaylightChart(
						solar: solar,
						timeZone: location.timeZone,
						eventTypes: [],
						includesSummaryTitle: false,
						markSize: 3,
						yScale: -1.0...2.0
					)
					.padding(.horizontal, -1)
				}
			} else {
				WidgetMissingLocationView()
					.padding()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.modify {
			if #available(iOSApplicationExtension 17.0, watchOSApplicationExtension 10.0, *) {
				$0.containerBackground(.background, for: .widget)
			} else {
				$0.background()
			}
		}
	}
}

#if !os(macOS)
#Preview(
	"Solar Chart (Accessory Rectangular)",
	as: WidgetFamily.accessoryRectangular,
	widget: { SolarChartWidget() },
	timeline: SolsticeWidgetTimelineEntry.previewTimeline
)
#endif
