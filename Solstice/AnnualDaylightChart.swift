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
							yStart: .value("Astronomical Sunrise", solar.startOfDay.distance(to: astronomicalSunrise)),
							yEnd: .value("Astronomical Sunset", solar.startOfDay.distance(to: astronomicalSunset))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.astronomical))
					}
					
					if let nauticalSunrise = solar.nauticalSunrise?.withTimeZoneAdjustment(for: location.timeZone),
						 let nauticalSunset = solar.nauticalSunset?.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Nautical Twilight", solar.date, unit: .month),
							yStart: .value("Nautical Sunrise", solar.startOfDay.distance(to: nauticalSunrise)),
							yEnd: .value("Nautical Sunset", solar.startOfDay.distance(to: nauticalSunset))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.nautical))
					}
					
					if let civilSunrise = solar.civilSunrise?.withTimeZoneAdjustment(for: location.timeZone),
						 let civilSunset = solar.civilSunset?.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Civil Twilight", solar.date, unit: .month),
							yStart: .value("Civil Sunrise", solar.startOfDay.distance(to: civilSunrise)),
							yEnd: .value("Civil Sunset", solar.startOfDay.distance(to: civilSunset))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.civil))
					}
					
					if let sunrise = solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone),
						 let sunset = solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone) {
						BarMark(
							x: .value("Daylight", solar.date, unit: .month),
							yStart: .value("Sunrise", solar.startOfDay.distance(to: sunrise)),
							yEnd: .value("Sunset", solar.startOfDay.distance(to: sunset))
						)
						.foregroundStyle(by: .value("Phase", Solar.Phase.day))
					}
				}
			}
			.chartForegroundStyleScale(kvPairs)
			.chartYScale(domain: minYValue...maxYValue)
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
								Text("\(date, style: .time)")
							}
						}
					}
				}
			}
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
	
	var maxYValue: Double {
		monthlySolars.reduce(dayLength) { partialResult, solar in
			let maxForSolar = [solar.astronomicalSunset, solar.nauticalSunset, solar.civilSunset, solar.safeSunset]
				.compactMap { $0 }
				.map { solar.startOfDay.distance(to: $0) }
				.reduce(0.0) { partialResult, currentValue in
					max(partialResult, currentValue)
				}
			
			return max(maxForSolar, partialResult)
		}
	}
	
	var minYValue: Double {
		monthlySolars.reduce(0.0) { partialResult, solar in
			let minForSolar = [solar.astronomicalSunrise, solar.nauticalSunrise, solar.civilSunrise, solar.safeSunrise]
				.compactMap { $0 }
				.map { solar.startOfDay.distance(to: $0) }
				.reduce(0.0) { partialResult, currentValue in
					max(partialResult, currentValue)
				}
			
			return min(minForSolar, partialResult)
		}
	}
}

struct AnnualDaylightChart_Previews: PreviewProvider {
    static var previews: some View {
			AnnualDaylightChart(location: CurrentLocation())
    }
}
