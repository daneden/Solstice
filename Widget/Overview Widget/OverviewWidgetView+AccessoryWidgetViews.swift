//
//  OverviewWidgetView+AccessoryWidgetViews.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

#if !os(macOS)
import SwiftUI
import WidgetKit
import SunKit
import Suite

extension OverviewWidgetView {
	struct AccessoryCircularView: View {
		@Environment(\.widgetRenderingMode) var renderingMode
		var sun: Sun
		var location: SolsticeWidgetLocation
		
		var body: some View {
			DaylightChart(
				sun: sun,
				timeZone: location.timeZone,
				showEventTypes: false,
				appearance: renderingMode == .fullColor ? .graphical : .simple,
				includesSummaryTitle: false,
				hideXAxis: true,
				markSize: 2.5
			)
			.widgetAccentable()
			.background { AccessoryWidgetBackground() }
			.mask(Circle())
			.widgetLabel {
				Label(sun.daylightDuration.localizedString, systemImage: "sun.max")
			}
		}
	}
	
	struct AccessoryRectangularView: View {
		var isAfterTodaySunset: Bool
		var location: SolsticeWidgetLocation?
		var relevantSun: Sun?
		var comparisonSun: Sun?
		
		var body: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("\(Image(systemName: "sun.max")) Daylight \(isAfterTodaySunset ? Text("Tomorrow") : Text("Today"))")
						.font(.headline)
						.widgetAccentable()
						.imageScale(.small)
						.allowsTightening(true)
						.contentTransition(.interpolate)
					
					if let relevantSun {
						Text(relevantSun.daylightDuration.localizedString)
							.contentTransition(.numericText())
						
						Group {
							if let comparisonSun {
								let difference = relevantSun.daylightDuration - comparisonSun.daylightDuration
								Text("\(difference >= 0 ? "+" : "-")\(Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2)))")
							} else {
								Text(relevantSun.safeSunrise...relevantSun.safeSunset)
							}
						}
						.foregroundStyle(.secondary)
						.transition(.blurReplace)
					}
				}
				
				Spacer(minLength: 0)
			}
			.minimumScaleFactor(0.9)
		}
	}
}
#endif
