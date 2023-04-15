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
					GeometryReader { geom in
						if family != .systemSmall {
							DaylightChart(solar: solar,
														timeZone: location.timeZone,
														eventTypes: [.sunrise, .sunset],
														includesSummaryTitle: false,
														hideXAxis: true,
														markSize: 5)
							.padding(.horizontal, -20)
							.frame(maxHeight: 200)
							
							if family == .systemMedium {
								VStack {
									Spacer()
									Rectangle()
										.fill(.clear)
										.background(.background)
										.frame(width: geom.size.width, height: min(geom.size.height / 1.25, 100))
										.padding(.leading, geom.size.width * -0.5)
										.blur(radius: 20)
								}
							}
						}
					}
					
					VStack(alignment: .leading, spacing: 4) {
						if sizeCategory < .xLarge {
							WidgetLocationView(location: location)
						}
						
						Spacer()
						
						if let duration = relevantSolar?.daylightDuration.localizedString {
							if sizeCategory < .xLarge {
								Text("Daylight \(isAfterTodaySunset ? "Tomorrow" : "Today")")
									.font(.caption)
							}
							
							Text("\(duration)")
								.lineLimit(4)
								.widgetHeading()
								.fixedSize(horizontal: false, vertical: true)
						}
						
						Group {
							if let begins = relevantSolar?.safeSunrise.withTimeZoneAdjustment(for: location.timeZone),
								 let ends = relevantSolar?.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
								if family == .systemSmall {
									Text(begins...ends)
										.foregroundStyle(.secondary)
								} else {
									if let differenceString = relevantSolar?.differenceString {
										Text(differenceString)
											.lineLimit(4)
											.font(.footnote)
											.foregroundStyle(.secondary)
											.fixedSize(horizontal: false, vertical: true)
									}
									
									HStack {
										Label("\(begins, style: .time)", systemImage: "sunrise.fill")
										Spacer()
										Label("\(ends, style: .time)", systemImage: "sunset.fill")
									}
								}
							}
						}.font(.footnote.weight(.semibold))
					}.symbolRenderingMode(.hierarchical)
				#endif
				}
				.padding()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.background(.background)
			}
		} else {
			WidgetMissingLocationView()
		}
	}
}

struct OverviewWidgetView_Previews: PreviewProvider {
	static var previews: some View {
		OverviewWidgetView(entry: SolsticeWidgetTimelineEntry(date: Date(), location: .defaultLocation))
		#if os(watchOS)
			.previewContext(WidgetPreviewContext(family: .accessoryCircular))
		#else
			.previewContext(WidgetPreviewContext(family: .systemMedium))
		#endif
	}
}
