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
	
	var dayLength: Double = 60 * 60 * 24

	var body: some View {
		VStack(alignment: .leading) {
			Label("Daylight by Month", systemImage: "chart.bar.xaxis")
			
			Chart {
				ForEach(monthlySolars, id: \.date) { solar in
					if let astronomicalSunrise = solar.astronomicalSunrise?.withTimeZoneAdjustment(for: location.timeZone),
						 let astronomicalSunset = solar.astronomicalSunset?.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Astronomical Twilight", solar.date, unit: .month),
							yStart: .value("Astronomical Sunrise", max(0, solar.startOfDay.distance(to: astronomicalSunrise))),
							yEnd: .value("Astronomical Sunset", min(dayLength, solar.startOfDay.distance(to: astronomicalSunset)))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.astronomical))
					}
					
					if let nauticalSunrise = solar.nauticalSunrise?.withTimeZoneAdjustment(for: location.timeZone),
						 let nauticalSunset = solar.nauticalSunset?.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Nautical Twilight", solar.date, unit: .month),
							yStart: .value("Nautical Sunrise", max(0, solar.startOfDay.distance(to: nauticalSunrise))),
							yEnd: .value("Nautical Sunset", min(dayLength, solar.startOfDay.distance(to: nauticalSunset)))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.nautical))
					}
					
					if let civilSunrise = solar.civilSunrise?.withTimeZoneAdjustment(for: location.timeZone),
						 let civilSunset = solar.civilSunset?.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Civil Twilight", solar.date, unit: .month),
							yStart: .value("Civil Sunrise", max(0, solar.startOfDay.distance(to: civilSunrise))),
							yEnd: .value("Civil Sunset", min(dayLength, solar.startOfDay.distance(to: civilSunset)))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.civil))
					}
					
					if let sunrise = solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone),
						 let sunset = solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Daylight", solar.date, unit: .month),
							yStart: .value("Sunrise", max(0, solar.startOfDay.distance(to: sunrise))),
							yEnd: .value("Sunset", min(dayLength, solar.startOfDay.distance(to: sunset)))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.day))
					}
				}
			}
			.chartForegroundStyleScale(kvPairs)
			.chartYScale(domain: 0...dayLength)
			.chartYAxis {
				AxisMarks(values: stride(from: 0.0, through: dayLength, by: 60 * 60 * 4).compactMap { $0 }) { value in
					AxisTick()
					AxisGridLine()
					AxisValueLabel {
						let startOfDay = Date().startOfDay
						if let doubleValue = value.as(Double.self),
							 let date = startOfDay.addingTimeInterval(doubleValue) {
							if doubleValue == 0 {
								Text("Morning")
							} else if doubleValue == dayLength {
								Text("Evening")
							} else {
								Text(date, style: .time)
							}
						}
					}
				}
			}
		}
	}
	
	func isCurrentMonth(_ date: Date) -> Bool {
		return calendar.date(date, matchesComponents: calendar.dateComponents([.month], from: Date()))
	}
}

extension AnnualDaylightChart {
	var monthlySolars: Array<Solar> {
		guard let year = calendar.dateInterval(of: .year, for: Date()) else {
			return []
		}
		
		var lastDate = calendar.date(bySetting: .day, value: 21, of: year.start) ?? year.start
		lastDate = calendar.date(bySetting: .hour, value: 12, of lastDate) ?? lastDate
		var dates: Array<Date> = []
		
		while lastDate < year.end {
			dates.append(lastDate)
			lastDate = calendar.date(byAdding: .month, value: 1, to: lastDate)!
		}
		
		return dates.map { date in
			return Solar(for: date, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
		}.compactMap { $0 }
	}
}

extension AnnualDaylightChart: Equatable {
	static func == (lhs: AnnualDaylightChart<Location>, rhs: AnnualDaylightChart<Location>) -> Bool {
		return lhs.location.latitude == rhs.location.latitude &&
		lhs.location.longitude == rhs.location.longitude
	}
}

struct AnnualDaylightChart_Previews: PreviewProvider {
    static var previews: some View {
			AnnualDaylightChart(location: TemporaryLocation.placeholderLocation)
    }
}
