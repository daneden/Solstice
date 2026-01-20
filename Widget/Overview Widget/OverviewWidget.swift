//
//  OverviewWidget.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import SwiftUI

struct OverviewWidget: Widget {
#if os(iOS)
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular, .accessoryCircular]
#elseif os(macOS)
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
#elseif os(watchOS)
	static var supportedFamilies: [WidgetFamily] = [.accessoryInline, .accessoryCircular, .accessoryRectangular, .accessoryCorner]
#endif
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: SolsticeWidgetKind.OverviewWidget.rawValue,
			intent: ConfigurationIntent.self,
			provider: SolsticeTimelineProvider(widgetKind: .OverviewWidget, recommendationDescription: "Overview")
		) { timelineEntry in
			OverviewWidgetView(entry: timelineEntry)
				.widgetURL(timelineEntry.location?.url)
		}
		.configurationDisplayName("Daylight Today")
		.description("See today’s daylight length, how it compares to yesterday, and sunrise/sunset times.")
		.supportedFamilies(OverviewWidget.supportedFamilies)
	}
}

#if os(iOS)
#Preview(as: .systemMedium) {
	OverviewWidget()
} timeline: {
	SolsticeWidgetTimelineEntry(date: .now, location: .defaultLocation)
}
#endif
