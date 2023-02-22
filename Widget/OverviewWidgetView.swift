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
	var location: SolsticeWidgetLocation
	
	var entry: SolsticeWidgetTimelineEntry
	
	var solar: Solar? {
		Solar(coordinate: entry.location.coordinate)
	}
	
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			GeometryReader { geom in
				if family != .systemSmall {
					if let solar {
						DaylightChart(solar: solar,
													timeZone: location.timeZone,
													eventTypes: [.sunrise, .sunset],
													includesSummaryTitle: false,
													hideXAxis: true)
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
					if let title = location.title {
						Label(title, systemImage: "location")
							.font(.footnote.weight(.semibold))
							.symbolVariant(.fill)
					} else {
						Image("Solstice-Icon")
							.resizable()
							.frame(width: 16, height: 16)
					}
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

				if family != .systemSmall {
					if let differenceString = solar?.differenceString {
						Text(differenceString)
							.lineLimit(4)
							.font(.caption)
							.foregroundStyle(.secondary)
							.fixedSize(horizontal: false, vertical: true)
					}

					HStack {
						if let begins = solar?.safeSunrise.withTimeZoneAdjustment(for: location.timeZone) {
							Label("\(begins, style: .time)", systemImage: "sunrise.fill")
						}

						Spacer()

						if let ends = solar?.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
							Label("\(ends, style: .time)", systemImage: "sunset.fill")
						}
					}
					.font(.caption.weight(.semibold))
				} else {
					VStack(alignment: .leading) {
						if let begins = solar?.safeSunrise.withTimeZoneAdjustment(for: location.timeZone) {
							Label("\(begins, style: .time)", systemImage: "sunrise.fill")
						}

						if let ends = solar?.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
							Label("\(ends, style: .time)", systemImage: "sunset.fill")
						}
					}.font(.caption).foregroundColor(.secondary)
				}
			}.symbolRenderingMode(.hierarchical)
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(.background)
	}
}

//struct SolsticeWidgetOverview_Previews: PreviewProvider {
//	static var previews: some View {
//		Group {
//			Group {
//				ForEach(WidgetFamily.allCases, id: \.self) { family in
//					OverviewWidgetView()
//						.previewContext(WidgetPreviewContext(family: family))
//				}
//			}
//
//			Group {
//				ForEach(WidgetFamily.allCases, id: \.self) { family in
//					OverviewWidgetView()
//						.previewContext(WidgetPreviewContext(family: family))
//				}
//			}
//			.dynamicTypeSize(.accessibility1)
//		}
//	}
//}

extension WidgetFamily: CaseIterable {
	public static var allCases: [WidgetFamily] {
		[.systemExtraLarge, .systemLarge, .systemMedium, .systemSmall]
	}
}
