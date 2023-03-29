//
//  WidgetBundle.swift
//  Widget
//
//  Created by Daniel Eden on 19/02/2023.
//

import WidgetKit
import SwiftUI
import Solar

@main
struct SolsticeWidgets: WidgetBundle {
	var body: some Widget {
		SolsticeOverviewWidget()
		SolsticeCountdownWidget()
		#if !os(watchOS)
		SolsticeEquinoxSolsticeWidget()
		#endif
	}
}

struct SolsticeOverviewWidget: Widget {
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
			provider: SolsticeOverviewWidgetTimelineProvider()
		) { timelineEntry in
			OverviewWidgetView(entry: timelineEntry)
		}
		.configurationDisplayName("Daylight Today")
		.description("See today’s daylight length, how it compares to yesterday, and sunrise/sunset times.")
		.supportedFamilies(SolsticeOverviewWidget.supportedFamilies)
	}
}

struct SolsticeCountdownWidget: Widget {
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
			provider: SolsticeCountdownWidgetTimelineProvider()
		) { timelineEntry in
			let solar = Solar(for: timelineEntry.date, coordinate: timelineEntry.location.coordinate)!
			return CountdownWidgetView(solar: solar, location: timelineEntry.location)
		}
		.configurationDisplayName("Sunrise/Sunset Countdown")
		.description("See the time remaining until the next sunrise/sunset")
		.supportedFamilies(SolsticeCountdownWidget.supportedFamilies)
	}
}

#if !os(watchOS)
struct SolsticeEquinoxSolsticeWidget: Widget {
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
	
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: SolsticeWidgetKind.EquinoxSolsticeWidget.rawValue,
			intent: ConfigurationIntent.self,
			provider: SolsticeOverviewWidgetTimelineProvider()
		) { timelineEntry in
			EquinoxSolsticeWidgetView(entry: timelineEntry)
		}
		.configurationDisplayName("Equinox and Solstice Countdown")
		.description("See a model of the Earth and a countdown to the next equinox or solstice event")
		.supportedFamilies(SolsticeEquinoxSolsticeWidget.supportedFamilies)
	}
}
#endif
