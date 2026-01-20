//
//  SolarChartWidget.swift
//  Solstice
//
//  Created by Daniel Eden on 12/04/2023.
//

import WidgetKit
import SwiftUI

#if !os(macOS)
struct SolarChartWidget: Widget {
	static var supportedFamilies: [WidgetFamily] = [.accessoryRectangular]
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: SolsticeWidgetKind.SolarChartWidget.rawValue,
			intent: ConfigurationIntent.self,
			provider: SolsticeTimelineProvider(widgetKind: .SolarChartWidget, recommendationDescription: "Solar Chart")
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
	static var supportedFamilies: [WidgetFamily] = [.systemLarge]
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: SolsticeWidgetKind.SundialWidget.rawValue,
			intent: ConfigurationIntent.self,
			provider: SolsticeTimelineProvider(widgetKind: .SundialWidget, recommendationDescription: "Sundial")
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
