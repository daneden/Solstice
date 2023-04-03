//
//  OverviewWidgetView+AccessoryWidgetViews.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import SwiftUI
import WidgetKit
import Solar

extension OverviewWidgetView {
	struct AccessoryCircularView: View {
		@Environment(\.widgetRenderingMode) var renderingMode
		var solar: Solar
		var location: SolsticeWidgetLocation
		
		var body: some View {
			ZStack {
				AccessoryWidgetBackground()
				DaylightChart(
					solar: solar,
					timeZone: location.timeZone,
					eventTypes: [.sunset, .sunrise],
					appearance: renderingMode == .fullColor ? .graphical : .simple,
					includesSummaryTitle: false,
					hideXAxis: true,
					markSize: 2.5
				)
				.padding(.vertical, 8)
			}
			.widgetLabel {
				Label(solar.daylightDuration.localizedString, systemImage: "sun.max")
			}
		}
	}
	
	struct AccessoryRectangularView: View {
		var isAfterTodaySunset: Bool
		var relevantSolar: Solar?
		
		var body: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("\(Image(systemName: "sun.max")) Daylight \(isAfterTodaySunset ? "Tomorrow" : "Today")")
						.font(.headline)
						.widgetAccentable()
						.imageScale(.small)
						.allowsTightening(true)
					
					if let relevantSolar {
						Text(relevantSolar.daylightDuration.localizedString)
						
						Text(relevantSolar.safeSunrise...relevantSolar.safeSunset)
							.foregroundStyle(.secondary)
					}
				}
				Spacer(minLength: 0)
			}
		}
	}
}
