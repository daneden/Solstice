//
//  SolarDebuggingView.swift
//  Solstice
//
//  Created by Daniel Eden on 03/02/2026.
//

import SwiftUI
import CoreLocation

struct SolarDebuggingView: View {
	var solar: NTSolar?
	var timeZone: TimeZone?
	
	var body: some View {
		Group {
			LabeledContent {
				Text(String(describing: solar?.coordinate))
			} label: {
				Text("Coordinates")
			}
			
			LabeledContent {
				if let date = solar?.date {
					Text(date, style: .time)
				} else {
					Text("nil")
				}
			} label: {
				Text("Date")
			}
			
			LabeledContent {
				if let sunrise = solar?.sunrise {
					Text(sunrise, style: .time)
				} else {
					Text("nil")
				}
			} label: {
				Text("Sunrise")
			}
			
			LabeledContent {
				if let sunset = solar?.sunset {
					Text(sunset, style: .time)
				} else {
					Text("nil")
				}
			} label: {
				Text("Sunset")
			}
			
			LabeledContent {
				if let solarNoon = solar?.solarNoon {
					Text(solarNoon, style: .time)
				} else {
					Text("nil")
				}
			} label: {
				Text("Solar noon")
			}
			
			if let solar {
				solar.view
					.frame(height: 80)
					.clipShape(.rect(cornerRadius: 12, style: .continuous))
			}
		}
		.environment(\.timeZone, timeZone ?? .autoupdatingCurrent)
	}
}

func dateForLocalTime(year: Int, month: Int, day: Int, hour: Int, minute: Int, in timeZone: TimeZone) -> Date? {
	var components = DateComponents()
	components.year = year
	components.month = month
	components.day = day
	components.hour = hour
	components.minute = minute
	components.timeZone = timeZone
	// Calendar will interpret components as local time in provided timeZone and convert to absolute Date.
	return Calendar(identifier: .gregorian).date(from: components)
}

// Example usage for 3 Feb 2026, 10:30 AM in Christchurch, NZ:
let christchurchTimeZone = TimeZone(identifier: "Pacific/Auckland")!

#Preview {
	Form {
		if let localDate = dateForLocalTime(year: 2026, month: 3, day: 3, hour: 10, minute: 30, in: christchurchTimeZone) {
			SolarDebuggingView(solar: NTSolar(for: localDate, coordinate: CLLocationCoordinate2D(latitude: -43.533128, longitude: 172.6352929), timeZone: christchurchTimeZone), timeZone: christchurchTimeZone)
		}
	}
}
