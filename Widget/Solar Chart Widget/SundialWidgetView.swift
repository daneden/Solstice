//
//  SolarChartWidgetView 2.swift
//  Solstice
//
//  Created by Daniel Eden on 09/10/2025.
//

import SwiftUI
import WidgetKit
import Solar

struct SundialWidgetView: SolsticeWidgetView {
	var entry: SolsticeWidgetTimelineEntry
	
	var body: some View {
		Group {
			if let location {
				ZStack(alignment: .top) {
					HStack(alignment: .top) {
						Label("Solstice", image: .solstice)
							.fontWeight(.semibold)
							.fontDesign(.rounded)
						Spacer()
						if let title = location.title {
							HStack(alignment: .top, spacing: 4) {
								if entry.location?.isRealLocation == true {
									Image(systemName: "location")
								}

								Text(title)
									.multilineTextAlignment(.trailing)
									.allowsTightening(true)
							}
							.foregroundStyle(.secondary)
							.imageScale(.small)
							.frame(maxWidth: 80)
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
			} else if needsReconfiguration {
				WidgetNeedsReconfigurationView()
					.containerBackground(.background, for: .widget)
			} else if shouldShowPlaceholder {
				SundialWidgetView(entry: .placeholder)
					.redacted(reason: .placeholder)
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
