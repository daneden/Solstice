//
//  SolarChartWidget.swift
//  Solstice
//
//  Created by Daniel Eden on 12/04/2023.
//

import WidgetKit
import SwiftUI

#if os(watchOS) || os(iOS)
struct SolarChartWidget: Widget {
	static var supportedFamilies: [WidgetFamily] = [.accessoryRectangular]

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: SolsticeWidgetKind.SolarChartWidget.rawValue,
			intent: SolsticeConfigurationIntent.self,
			provider: SolsticeTimelineProvider(widgetKind: .SolarChartWidget)
		) { timelineEntry in
			SolarChartWidgetView(entry: timelineEntry)
				.widgetURL(timelineEntry.location?.url)
		}
		.configurationDisplayName("Solar Chart")
		.description("Follow the sun's journey throughout the day")
		.supportedFamilies(Self.supportedFamilies)
	}
}
#endif

#if !os(watchOS)
struct SundialWidget: Widget {
	static var supportedFamilies: [WidgetFamily] = [.systemLarge, .systemSmall]

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: SolsticeWidgetKind.SundialWidget.rawValue,
			intent: SolsticeConfigurationIntent.self,
			provider: SolsticeTimelineProvider(widgetKind: .SundialWidget)
		) { timelineEntry in
			SundialWidgetView(entry: timelineEntry)
				.widgetURL(timelineEntry.location?.url)
		}
		.configurationDisplayName("Sundial")
		.description("Follow the sun's journey throughout the day")
		.supportedFamilies(Self.supportedFamilies)
	}
}
#endif
