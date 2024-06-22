//
//  DaylightSummaryRow.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import Solar
import CoreLocation

struct DaylightSummaryRow<Location: ObservableLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine
	@ObservedObject var location: Location
	
	@AppStorage(Preferences.listViewShowComplication) private var showComplication
	
	@State private var showRemainingDaylight = false
	
	var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
	}
	
	var isCurrentLocation: Bool {
		location is CurrentLocation
	}
	
	var subtitle: String? {
		if location is CurrentLocation && location.title == nil {
			return "—"
		} else {
			return location.subtitle
		}
	}
	
	@ViewBuilder
	var trailingContent: some View {
		if let solar {
			VStack(alignment: .trailing) {
				Text(Duration.seconds(solar.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
					.foregroundStyle(.secondary)
				Text(solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)...solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone))
					.font(.footnote)
					.foregroundStyle(.tertiary)
			}
			.contentTransition(.numericText())
			
			if showComplication {
				DaylightChart(
					solar: solar,
					timeZone: location.timeZone,
					showEventTypes: false,
					includesSummaryTitle: false,
					hideXAxis: true,
					markSize: 2
				)
				.frame(width: 36, height: 36)
				#if !os(watchOS)
				.background(.ultraThinMaterial)
				#endif
				.ellipticalEdgeMask()
				.transition(
					.move(edge: .trailing)
					.combined(with: .opacity)
				)
			}
		}
	}
	
	var body: some View {
			HStack {
				VStack(alignment: .leading, spacing: 2) {
					HStack {
						if location is CurrentLocation {
							Image(systemName: "location")
								.imageScale(.small)
								.foregroundStyle(.secondary)
								.symbolVariant(.fill)
						}
						
						Group {
							if let title = location.title {
								Text(verbatim: title)
									.id(location.title)
							} else {
								Text("Current location")
							}
						}
						.modify { content in
							if #available(iOS 17, macOS 14, watchOS 10, *) {
								content.transition(.blurReplace)
							} else {
								content.transition(.scale)
							}
						}
						.lineLimit(2)
					}
					
					if let subtitle,
						 !subtitle.isEmpty {
						Text(subtitle)
							.id(subtitle)
							.foregroundStyle(.secondary)
							.font(.footnote)
							.modify { content in
								if #available(iOS 17, macOS 14, watchOS 10, *) {
									content.transition(.blurReplace)
								} else {
									content.transition(.scale)
								}
							}
					}
				}
				.animation(.default, value: location.title)
				
				Spacer()
				
				trailingContent
			}
		.padding(.vertical, 4)
	}
}

struct DaylightSummaryRow_Previews: PreviewProvider {
	static var previews: some View {
		List {
			DaylightSummaryRow(location: TemporaryLocation.placeholderLondon)
		}
		.environmentObject(TimeMachine.preview)
	}
}
