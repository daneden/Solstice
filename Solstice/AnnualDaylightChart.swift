//
//  AnnualDaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import SwiftUI
import Solar
import CoreLocation
import Charts

struct AnnualDaylightChart<Location: AnyLocation>: View {
	var location: Location
	
	var kvPairs: KeyValuePairs<Solar.Phase, Color> = [
		.astronomical: .indigo,
		.nautical: .blue,
		.civil: .teal,
		.day: .yellow
	]
	
	var body: some View {
		VStack(alignment: .leading) {
			Label("Daylight by Month", systemImage: "chart.bar.xaxis")
			
			Chart {
				ForEach(monthlySolars, id: \.date) { solar in
					let tzOffset = TimeInterval(location.timeZone.secondsFromGMT(for: solar.date))
					
					if let astronomicalSunrise = solar.astronomicalSunrise,
						 let astronomicalSunset = solar.astronomicalSunset {
						BarMark(
							xStart: .value("Astronomical Sunrise", solar.startOfDay.distance(to: astronomicalSunrise) + tzOffset),
							xEnd: .value("Astronomical Sunset", solar.startOfDay.distance(to: astronomicalSunset) + tzOffset),
							y: .value("Astronomical Twilight", solar.date, unit: .month)
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.astronomical))
					}
					
					if let nauticalSunrise = solar.nauticalSunrise,
						 let nauticalSunset = solar.nauticalSunset {
						BarMark(
							xStart: .value("Nautical Sunrise", solar.startOfDay.distance(to: nauticalSunrise) + tzOffset),
							xEnd: .value("Nautical Sunset", solar.startOfDay.distance(to: nauticalSunset) + tzOffset),
							y: .value("Nautical Twilight", solar.date, unit: .month)
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.nautical))
					}
					
					if let civilSunrise = solar.civilSunrise,
						 let civilSunset = solar.civilSunset {
						BarMark(
							xStart: .value("Civil Sunrise", solar.startOfDay.distance(to: civilSunrise) + tzOffset),
							xEnd: .value("Civil Sunset", solar.startOfDay.distance(to: civilSunset) + tzOffset),
							y: .value("Civil Twilight", solar.date, unit: .month)
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.civil))
					}
					
					if let sunrise = solar.sunrise,
						 let sunset = solar.sunset {
						BarMark(
							xStart: .value("Sunrise", solar.startOfDay.distance(to: sunrise) + tzOffset),
							xEnd: .value("Sunset", solar.startOfDay.distance(to: sunset) + tzOffset),
							y: .value("Daylight", solar.date, unit: .month)
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.day))
					}
				}
			}
			.chartForegroundStyleScale(kvPairs)
			.chartXScale(domain: 0...(60 * 60 * 24))
		}
	}
	
	func isCurrentMonth(_ date: Date) -> Bool {
		return Calendar.autoupdatingCurrent.date(date, matchesComponents: Calendar.autoupdatingCurrent.dateComponents([.month], from: Date()))
	}
}

extension AnnualDaylightChart {
	var monthlySolars: Array<Solar> {
		guard let year = Calendar.autoupdatingCurrent.dateInterval(of: .year, for: Date()) else {
			return []
		}
		
		var lastDate = Calendar.current.date(bySetting: .hour, value: 12, of: year.start) ?? year.start
		var dates: Array<Date> = []
		
		while lastDate < year.end {
			dates.append(lastDate)
			lastDate = Calendar.current.date(byAdding: .month, value: 1, to: lastDate)!
		}
		
		return dates.map { date in
			return Solar(for: date, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
		}.compactMap { $0 }
	}
}

struct AnnualDaylightChart_Previews: PreviewProvider {
    static var previews: some View {
			AnnualDaylightChart(location: CurrentLocation())
    }
}
