//
//  SolarChartWidgetView 2.swift
//  Solstice
//
//  Created by Daniel Eden on 09/10/2025.
//


//
//  SolarChartWidgetView.swift
//  Solstice
//
//  Created by Daniel Eden on 12/04/2023.
//

import SwiftUI
import WidgetKit
import Solar

struct SundialWidgetView: View {
	var entry: SolsticeWidgetTimelineEntry
	
	var location: SolsticeWidgetLocation? {
		entry.location
	}
	
	var body: some View {
		Group {
			if let location {
				CircularSolarChart(location: location)
			} else {
				WidgetMissingLocationView()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.containerBackground(.background, for: .widget)
	}
}

#if !os(macOS)
#Preview(as: .systemLarge) {
	SundialWidget()
} timeline: {
	SolsticeWidgetTimelineEntry(date: .now, location: .defaultLocation)
}
#endif
