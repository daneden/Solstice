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

struct SolsticeWidgetLocation {
	var name: String
	var timeZone: TimeZone
	var location: CLLocationCoordinate2D
}

struct OverviewWidgetView: View {
	@Environment(\.widgetFamily) private var family
	@Environment(\.sizeCategory) private var sizeCategory
	@State var detailedLocation: SolsticeWidgetLocation?
	
	var entry: SolsticeWidgetTimelineEntry
	
	var solar: Solar? {
		Solar(coordinate: entry.location)
	}
	
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			GeometryReader { geom in
				if family != .systemSmall {
					if let solar {
						DaylightChart(solar: solar,
													timeZone: detailedLocation?.timeZone ?? .autoupdatingCurrent,
													includesSummaryTitle: false,
													hideXAxis: true)
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
					if let detailedLocation {
						Label(detailedLocation.name, systemImage: "location")
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
						if let begins = solar?.safeSunrise {
							Label("\(begins, style: .time)", systemImage: "sunrise.fill")
						}

						Spacer()

						if let ends = solar?.safeSunset {
							Label("\(ends, style: .time)", systemImage: "sunset.fill")
						}
					}.font(.caption)
				} else {
					VStack(alignment: .leading) {
						if let begins = solar?.safeSunrise {
							Label("\(begins, style: .time)", systemImage: "sunrise.fill")
						}

						if let ends = solar?.safeSunset {
							Label("\(ends, style: .time)", systemImage: "sunset.fill")
						}
					}.font(.caption).foregroundColor(.secondary)
				}
			}.symbolRenderingMode(.hierarchical).imageScale(.large)
		}
		.task {
			guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: entry.location.latitude, longitude: entry.location.longitude)).first else {
				return
			}
			
			detailedLocation = SolsticeWidgetLocation(name: placemark.name ?? "Unknown Location",
																								timeZone: placemark.timeZone ?? .autoupdatingCurrent,
																								location: entry.location)
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
