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
						
						Text(location.title ?? "My Location")
							.lineLimit(2)
					}
					
					if let subtitle = location.subtitle,
						 !subtitle.isEmpty {
						Text(subtitle)
							.foregroundStyle(.secondary)
							.font(.footnote)
					}
				}
				
				Spacer()
				
				if let solar {
					VStack(alignment: .trailing) {
						Text(Duration.seconds(solar.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
							.foregroundStyle(.secondary)
						Text(solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)...solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone))
							.font(.footnote)
							.foregroundStyle(.tertiary)
					}
					
					if showComplication {
						DaylightChart(
							solar: solar,
							timeZone: location.timeZone,
							eventTypes: [.sunrise, .sunset],
							includesSummaryTitle: false,
							hideXAxis: true,
							markSize: 2
						)
						.frame(width: 36, height: 36)
#if !os(watchOS)
						.background(.ultraThinMaterial)
#endif
						.ellipticalEdgeMask()
						.transition(.scale(scale: 0, anchor: .trailing))
					}
				}
			}
		.padding(.vertical, 4)
	}
}

struct DaylightSummaryRow_Previews: PreviewProvider {
	static var previews: some View {
		List {
			DaylightSummaryRow(location: TemporaryLocation.placeholderLocation)
		}
		.environmentObject(TimeMachine.preview)
	}
}
