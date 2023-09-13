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
		var location: SolsticeWidgetLocation?
		var relevantSolar: Solar?
		var comparisonSolar: Solar?
		
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
						
						if let comparisonSolar {
							let difference = relevantSolar.daylightDuration - comparisonSolar.daylightDuration
							Text("\(difference >= 0 ? "+" : "-")\(Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2)))")
								.foregroundStyle(.secondary)
						} else {
							Text(relevantSolar.safeSunrise...relevantSolar.safeSunset)
								.foregroundStyle(.secondary)
						}
					}
				}
				
				Spacer(minLength: 0)
			}
		}
	}
}
