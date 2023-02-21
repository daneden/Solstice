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
				
				Text(sunrise...sunset)
					.font(.footnote)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Text(sunrise.distance(to: sunset).formatted(.timeInterval(allowedUnits: [.hour, .minute], unitsStyle: .abbreviated, zeroFormattingBehaviour: .pad)))
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
		var timezone: TimeZone = .autoupdatingCurrent
		if let timezoneIdentifier = location.timeZoneIdentifier,
			 let specifiedTimezone = TimeZone(identifier: timezoneIdentifier) {
			timezone = specifiedTimezone
		}
		let returnValue = solar?.safeSunrise ?? .now
		return returnValue.addingTimeInterval(TimeInterval(timezone.secondsFromGMT(for: date)))
	}
	
	var sunset: Date {
		var timezone: TimeZone = .autoupdatingCurrent
		if let timezoneIdentifier = location.timeZoneIdentifier,
			 let specifiedTimezone = TimeZone(identifier: timezoneIdentifier) {
			timezone = specifiedTimezone
		}
		let returnValue = solar?.safeSunset ?? .now
		return returnValue.addingTimeInterval(TimeInterval(timezone.secondsFromGMT(for: date)))
	}
}

struct DaylightSummaryRow_Previews: PreviewProvider {
    static var previews: some View {
        DaylightSummaryRow(location: CurrentLocation())
    }
}
