//
//  OverviewWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 19/02/2023.
//

import SwiftUI
import WidgetKit
import Solar

struct OverviewWidgetView: View {
	@Environment(\.widgetRenderingMode) private var renderingMode
	@Environment(\.widgetFamily) private var family
	@Environment(\.dynamicTypeSize) private var sizeCategory
	
	var entry: SolsticeWidgetTimelineEntry
	
	var solar: Solar? {
		guard let location else { return nil }
		return Solar(for: entry.date, coordinate: location.coordinate)
	}
	
	var tomorrowSolar: Solar? {
		solar?.tomorrow
	}
	
	var relevantSolar: Solar? {
		isAfterTodaySunset ? tomorrowSolar : solar
	}
	
	var isAfterTodaySunset: Bool {
		guard let solar else { return false }
		return solar.safeSunset < entry.date
	}
	
	var location: SolsticeWidgetLocation? {
		entry.location
	}
	
	var body: some View {
		Group {
			if let solar,
				 let location {
				switch family {
#if !os(macOS)
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
								.widgetAccentable()
						}
#endif // end watchOS
#endif // end !macOS
				default:
					ZStack(alignment: .bottomLeading) {
#if !os(watchOS)
						if family != .systemSmall {
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
							if sizeCategory < .xLarge {
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
								if let begins = relevantSolar?.safeSunrise.withTimeZoneAdjustment(for: location.timeZone),
									 let ends = relevantSolar?.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
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
				}
			} else {
				WidgetMissingLocationView()
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			}
		}
		.backwardCompatibleContentMargins()
		.backwardCompatibleContainerBackground(.background)
	}
}

#if os(iOS)
#Preview(
	"Overview (System Small)",
	as: WidgetFamily.systemSmall,
	widget: { OverviewWidget() },
	timeline: SolsticeWidgetTimelineEntry.previewTimeline
)
#endif

