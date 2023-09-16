//
//  CountdownWidget.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import SwiftUI
import Solar

struct CountdownWidget: Widget {
#if os(iOS)
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular, .accessoryCircular]
#elseif os(macOS)
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium]
#elseif os(watchOS)
	static var supportedFamilies: [WidgetFamily] = [.accessoryInline, .accessoryCircular, .accessoryRectangular, .accessoryCorner]
#endif
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: SolsticeWidgetKind.CountdownWidget.rawValue,
			intent: ConfigurationIntent.self,
			provider: CountdownWidgetTimelineProvider()
		) { timelineEntry in
			CountdownWidgetView(entry: timelineEntry)
				.modify {
					if #available(macOSApplicationExtension 14, iOSApplicationExtension 14, watchOSApplicationExtension 14, *) {
						$0.containerBackground(
							LinearGradient(colors: SkyGradient.getCurrentPalette(for: Solar(for: timelineEntry.date, coordinate: (timelineEntry.location ?? .defaultLocation).coordinate)),
														 startPoint: .top,
														 endPoint: .bottom),
							for: .widget
						)
					} else {
						$0.background {
							LinearGradient(colors: SkyGradient.getCurrentPalette(for: Solar(for: timelineEntry.date, coordinate: (timelineEntry.location ?? .defaultLocation).coordinate)),
														 startPoint: .top,
														 endPoint: .bottom)
						}
					}
				}
		}
		.configurationDisplayName("Sunrise/Sunset Countdown")
		.description("See the time remaining until the next sunrise/sunset")
		.supportedFamilies(CountdownWidget.supportedFamilies)
	}
}

#if !os(macOS)
#Preview(as: WidgetFamily.accessoryRectangular) {
	CountdownWidget()
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
	CountdownWidget()
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
