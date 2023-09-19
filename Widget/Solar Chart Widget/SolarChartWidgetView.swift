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
		if let solar,
			 let location {
			ZStack(alignment: .topLeading) {
				HStack {
					Label {
						Text(solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone), style: .time)
					} icon: {
						Image(systemName: "sunrise")
					}
					
					Spacer()
					
					Label {
						Text(solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone), style: .time)
					} icon: {
						Image(systemName: "sunset")
					}
				}
				.symbolVariant(.fill)
				.imageScale(.small)
				.font(.footnote)
				.widgetAccentable()
				
				DaylightChart(
					solar: solar,
					timeZone: location.timeZone,
					eventTypes: [],
					includesSummaryTitle: false,
					markSize: 3
				)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		} else {
			WidgetMissingLocationView()
		}
	}
}

struct SolarChartWidgetView_Previews: PreviewProvider {
	static var previews: some View {
		SolarChartWidgetView(entry: SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
			.previewContext(WidgetPreviewContext(family: .accessoryRectangular))
	}
}
