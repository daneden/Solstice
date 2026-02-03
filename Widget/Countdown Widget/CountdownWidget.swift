//
//  CountdownWidget.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import WidgetKit
import SwiftUI

struct CountdownWidget: Widget {
#if os(iOS)
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular, .accessoryCircular]
#elseif os(macOS) || os(visionOS)
	static var supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium]
#elseif os(watchOS)
	static var supportedFamilies: [WidgetFamily] = [.accessoryInline, .accessoryCircular, .accessoryRectangular, .accessoryCorner]
#endif

	@ViewBuilder
	private func widgetContent(for timelineEntry: SolsticeWidgetTimelineEntry) -> some View {
		CountdownWidgetView(entry: timelineEntry)
			.containerBackground(for: .widget) {
				SkyGradient(ntSolar: NTSolar(for: timelineEntry.date, coordinate: (timelineEntry.location ?? .defaultLocation).coordinate, timeZone: (timelineEntry.location ?? .defaultLocation).timeZone))
			}
			.widgetURL(timelineEntry.location?.url)
	}

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: SolsticeWidgetKind.CountdownWidget.rawValue,
			intent: SolsticeConfigurationIntent.self,
			provider: SolsticeTimelineProvider(widgetKind: .CountdownWidget)
		) { timelineEntry in
			widgetContent(for: timelineEntry)
		}
		.configurationDisplayName("Sunrise/Sunset Countdown")
		.description("See the time remaining until the next sunrise/sunset")
		.supportedFamilies(CountdownWidget.supportedFamilies)
	}
}
