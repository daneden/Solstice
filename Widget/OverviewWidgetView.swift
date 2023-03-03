//
//  OverviewWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 19/02/2023.
//

import SwiftUI
import WidgetKit
import Solar
import CoreLocation

struct SolsticeWidgetLocation: AnyLocation {
	var title: String?
	var subtitle: String?
	var timeZoneIdentifier: String?
	var latitude: Double
	var longitude: Double
	var isRealLocation = false
	
	var timeZone: TimeZone {
		guard let timeZoneIdentifier else { return .autoupdatingCurrent }
		return TimeZone(identifier: timeZoneIdentifier) ?? .autoupdatingCurrent
	}
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	static var defaultLocation = SolsticeWidgetLocation(title: "London",
																											subtitle: "United Kingdom",
																											timeZoneIdentifier: "GMT",
																											latitude: 51.5072,
																											longitude: -0.1276)
}

struct OverviewWidgetView: View {
	@Environment(\.widgetFamily) private var family
	@Environment(\.sizeCategory) private var sizeCategory
	
	var entry: SolsticeWidgetTimelineEntry
	
	var solar: Solar? {
		Solar(coordinate: entry.location.coordinate)
	}
	
	var location: SolsticeWidgetLocation {
		entry.location
	}
	
	var body: some View {
		switch family {
			#if !os(macOS)
		case .accessoryCircular:
			ZStack {
				AccessoryWidgetBackground()
				if let solar {
					DaylightChart(
						solar: solar,
						timeZone: location.timeZone,
						eventTypes: [.sunset, .sunrise],
						includesSummaryTitle: false,
						hideXAxis: true,
						markSize: 2.5
					)
					.padding(.vertical, 8)
				}
			}
			.widgetLabel {
				Label(solar?.daylightDuration.localizedString ?? "Loading...", systemImage: "sun.max")
			}
			#endif
		case .accessoryInline:
			Label(solar?.daylightDuration.localizedString ?? "Loading...", systemImage: "sun.max")
		case .accessoryRectangular:
			VStack(alignment: .leading) {
				Label(solar?.daylightDuration.localizedString ?? "Loading...", systemImage: "sun.max")
					.font(.headline)
				if let solar {
					Text(solar.safeSunrise...solar.safeSunset)
						.foregroundStyle(.secondary)
				}
			}
		default:
			ZStack(alignment: .bottomLeading) {
				#if !os(watchOS)
				GeometryReader { geom in
					if family != .systemSmall {
						if let solar {
							DaylightChart(solar: solar,
														timeZone: location.timeZone,
														eventTypes: [.sunrise, .sunset],
														includesSummaryTitle: false,
														hideXAxis: true,
														markSize: 5)
							.padding(.horizontal, -20)
							.frame(maxHeight: 200)
						}
						
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
					if sizeCategory < .extraLarge {
						WidgetLocationView(location: location)
					}
					
					Spacer()
					
					if let duration = solar?.daylightDuration.localizedString {
						if sizeCategory < .extraLarge {
							Text("Daylight today:")
								.font(.caption)
						}
						
						Text("\(duration)")
							.lineLimit(4)
							.font(Font.system(family == .systemSmall ? .footnote : .headline, design: .rounded).bold().leading(.tight))
							.fixedSize(horizontal: false, vertical: true)
					}
					
					Group {
						if let begins = solar?.safeSunrise.withTimeZoneAdjustment(for: location.timeZone),
							 let ends = solar?.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
							if family == .systemSmall {
								Text(begins...ends)
									.foregroundStyle(.secondary)
							} else {
								if let differenceString = solar?.differenceString {
									Text(differenceString)
										.lineLimit(4)
										.font(.caption)
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
					}.font(.caption.weight(.medium))
				}.symbolRenderingMode(.hierarchical)
				#endif
			}
			.padding()
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(.background)
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
