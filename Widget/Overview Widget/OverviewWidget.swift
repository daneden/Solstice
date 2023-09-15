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
			provider: OverviewWidgetTimelineProvider()
		) { timelineEntry in
			OverviewWidgetView(entry: timelineEntry)
		}
		.configurationDisplayName("Daylight Today")
		.description("See today’s daylight length, how it compares to yesterday, and sunrise/sunset times.")
		.supportedFamilies(OverviewWidget.supportedFamilies)
		.contentMarginsDisabled()
	}
}

#if !os(macOS)
#Preview(as: WidgetFamily.accessoryRectangular) {
	OverviewWidget()
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
	OverviewWidget()
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
