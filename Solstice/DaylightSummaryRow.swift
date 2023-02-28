//
//  DaylightSummaryRow.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import Solar
import CoreLocation

fileprivate var daylightFormatter: DateComponentsFormatter {
	let formatter = DateComponentsFormatter()
	formatter.allowedUnits = [.hour, .minute]
	formatter.unitsStyle = .abbreviated
	
	return formatter
}

struct DaylightSummaryRow<Location: ObservableLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine
	@ObservedObject var location: Location
	
	@State private var showRemainingDaylight = false
	
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
					}
					
					Text(location.title ?? "My Location")
				}
				
				Text(sunrise.withTimeZoneAdjustment(for: location.timeZone)...sunset.withTimeZoneAdjustment(for: location.timeZone))
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
			
			Text(daylightFormatter.string(from: sunrise.distance(to: sunset)) ?? "")
				.font(.title)
				.fontWeight(.light)
				.foregroundStyle(.secondary)
		}
		.padding(.vertical, 4)
	}
}

extension DaylightSummaryRow {
	var date: Date {
		timeMachine.date
	}
	
	var solar: Solar? {
		Solar(for: date, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
	}
	
	var sunrise: Date {
		solar?.safeSunrise ?? .now
	}
	
	var sunset: Date {
		solar?.safeSunset ?? .now
	}
}

struct DaylightSummaryRow_Previews: PreviewProvider {
	static var previews: some View {
		DaylightSummaryRow(location: TemporaryLocation.placeholderLocation)
			.environmentObject(TimeMachine())
	}
}
