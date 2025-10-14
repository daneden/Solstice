//
//  SolarChartWidgetView 2.swift
//  Solstice
//
//  Created by Daniel Eden on 09/10/2025.
//

import SwiftUI
import WidgetKit
import Solar

struct SundialWidgetView: View {
	var entry: SolsticeWidgetTimelineEntry
	
	var location: SolsticeWidgetLocation? {
		entry.location
	}
	
	var solar: Solar? {
		guard let location else { return nil }
		return Solar(for: entry.date, coordinate: location.coordinate)
	}
	
	var body: some View {
		Group {
			if let location {
				ZStack(alignment: .top) {
					HStack {
						Label("Solstice", image: .solstice)
							.fontWeight(.bold)
						Spacer()
						if let title = location.title {
							Label(title, systemImage: entry.location?.isRealLocation == true ? "location" : "mappin")
								.foregroundStyle(.secondary)
								.imageScale(.small)
						}
					}
					.symbolVariant(.fill)
					.font(.footnote.weight(.medium))
					.labelStyle(CompactLabelStyle())
					CircularSolarChart(date: entry.date, location: location)
				}
				.containerBackground(for: .widget) {
					solar?.view.opacity(0.15)
					}
			} else {
				WidgetMissingLocationView()
				.containerBackground(.background, for: .widget)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

#if !os(macOS)
#Preview(as: .systemLarge) {
	SundialWidget()
} timeline: {
	SolsticeWidgetTimelineEntry(date: .now, location: .defaultLocation)
}
#endif
