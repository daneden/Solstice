//
//  OverviewWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 19/02/2023.
//

import SwiftUI
import WidgetKit

struct OverviewWidgetView: SolsticeWidgetView {
	@Environment(\.widgetRenderingMode) private var renderingMode
	@Environment(\.widgetFamily) private var family
	@Environment(\.dynamicTypeSize) private var sizeCategory
	
	var entry: SolsticeWidgetTimelineEntry
	
	var body: some View {
		Group {
			if let solar,
				 let location {
				switch family {
				#if os(watchOS) || os(iOS)
				case .accessoryCircular:
					AccessoryCircularView(solar: solar, location: location)
				case .accessoryInline:
					Label(solar.daylightDuration.localizedString, systemImage: "sun.max")
				case .accessoryRectangular:
					AccessoryRectangularView(
						isAfterTodaySunset: isAfterTodaySunset,
						location: location,
						relevantSolar: relevantSolar,
						comparisonSolar: isAfterTodaySunset ? solar : nil
					)
				#if os(watchOS)
				case .accessoryCorner:
					Image(systemName: "sun.max")
						.font(.title.bold())
						.symbolVariant(.fill)
						.imageScale(.large)
						.widgetLabel {
							Text(solar.daylightDuration.localizedString)
						}
						.widgetAccentable()
				#endif // end watchOS
				#endif // end !macOS
				default:
					RectangularView(entry: entry)
				}
			} else if needsReconfiguration {
				WidgetNeedsReconfigurationView()
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			} else if shouldShowPlaceholder {
				RectangularView(entry: .placeholder)
					.redacted(reason: .placeholder)
			} else {
				WidgetMissingLocationView()
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			}
		}
		.containerBackground(for: .widget) {
			Color.clear.background(.background)
		}
		.environment(\.timeZone, location?.timeZone ?? .autoupdatingCurrent)
	}
}

extension OverviewWidgetView {
	struct RectangularView: SolsticeWidgetView {
		@Environment(\.widgetFamily) private var family
		@Environment(\.dynamicTypeSize) private var sizeCategory
		
		var entry: SolsticeWidgetTimelineEntry
		
		var body: some View {
			ZStack(alignment: .bottomLeading) {
				#if !os(watchOS)
				if family != .systemSmall,
					 let solar,
					 let location {
					GeometryReader { geom in
						DaylightChart(
							solar: solar,
							timeZone: location.timeZone,
							showEventTypes: false,
							includesSummaryTitle: false,
							hideXAxis: true,
							markSize: family == .systemSmall ? 3 : 5
						)
						.frame(maxHeight: 250)
						.mask {
							if family == .systemMedium || family == .systemSmall {
								RadialGradient(
									colors: [.black.opacity(0.1), .black],
									center: .bottomLeading,
									startRadius: geom.size.height / 1.2,
									endRadius: geom.size.height
								)
							} else {
								Color.black
							}
						}
					}
					.padding(-20)
				}
				
				VStack(alignment: .leading, spacing: 4) {
					if sizeCategory < .xLarge,
						 let location {
						WidgetLocationView(location: location)
					}
					
					Spacer()
					
					if let duration = relevantSolar?.daylightDuration.localizedString {
						if sizeCategory < .xLarge {
							Group {
								if isAfterTodaySunset {
									Text("Daylight tomorrow")
								} else {
									Text("Daylight today")
								}
							}
							.font(.footnote)
						}
						
						Text(duration)
							.lineLimit(4)
							.widgetHeading()
							.fixedSize(horizontal: false, vertical: true)
							.contentTransition(.numericText())
					}
					
					Group {
						if let location,
							 let begins = relevantSolar?.safeSunrise,
							 let ends = relevantSolar?.safeSunset {
							if let differenceString = relevantSolar?.compactDifferenceString {
								Text(differenceString)
									.lineLimit(4)
									.font(.footnote)
									.foregroundStyle(.secondary)
									.fixedSize(horizontal: false, vertical: true)
							}
							
							if family == .systemSmall {
								Text(begins...ends)
									.foregroundStyle(.tertiary)
							} else {
								HStack {
									Label {
										Text(begins, style: .time)
									} icon: {
										Image(systemName: "sunrise.fill")
									}
									
									Spacer()
									
									Label {
										Text(ends, style: .time)
									} icon: {
										Image(systemName: "sunset.fill")
									}
								}
							}
						}
					}
					.font(.footnote.weight(.semibold))
					.contentTransition(.numericText())
				}
				.symbolRenderingMode(.hierarchical)
#endif
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			.environment(\.timeZone, location?.timeZone ?? .autoupdatingCurrent)
		}
	}
}

#if os(iOS)
#Preview(as: .systemMedium,
				 widget: { OverviewWidget() },
				 timeline: SolsticeWidgetTimelineEntry.previewTimeline)
#endif
