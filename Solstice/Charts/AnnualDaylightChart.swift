//
//  AnnualDaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import SwiftUI
import Solar
import Charts
import TimeMachine

struct AnnualDaylightChart<Location: AnyLocation>: View {
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	var location: Location
	
	var kvPairs: KeyValuePairs<Solar.Phase, Color> = [
		.astronomical: .indigo,
		.nautical: .blue,
		.civil: .teal,
		.day: .yellow
	]
	
	var dayLength: Double = 60 * 60 * 24
	
	var body: some View {
		Chart {
			currentMonthIndicator
			monthlyBarMarks
		}
		.chartForegroundStyleScale(kvPairs)
		.chartYScale(domain: 0...dayLength)
		.chartYAxis { yAxisMarks }
	}

	private var currentMonthIndicator: some ChartContent {
		BarMark(x: .value("Current month", timeMachine.date, unit: .month))
			.foregroundStyle(.quaternary)
	}

	private var monthlyBarMarks: some ChartContent {
		ForEach(monthlySolars, id: \.date) { solar in
			solarBarMarks(for: solar)
		}
	}

	@ChartContentBuilder
	private func solarBarMarks(for solar: Solar) -> some ChartContent {
		astronomicalBarMark(for: solar)
		nauticalBarMark(for: solar)
		civilBarMark(for: solar)
		daylightBarMark(for: solar)
	}

	@ChartContentBuilder
	private func astronomicalBarMark(for solar: Solar) -> some ChartContent {
		if let astronomicalSunrise = solar.astronomicalSunrise?.withTimeZoneAdjustment(for: location.timeZone),
			 let astronomicalSunset = solar.astronomicalSunset?.withTimeZoneAdjustment(for: location.timeZone) {
			let yStart: Double = max(0, solar.startOfDay.distance(to: astronomicalSunrise))
			let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: astronomicalSunset))
			BarMark(
				x: .value("Astronomical Twilight", solar.date, unit: .month),
				yStart: .value("Astronomical Sunrise", yStart),
				yEnd: .value("Astronomical Sunset", yEnd)
			)
			.foregroundStyle(by: .value("Phase", Solar.Phase.astronomical))
		}
	}

	@ChartContentBuilder
	private func nauticalBarMark(for solar: Solar) -> some ChartContent {
		if let nauticalSunrise = solar.nauticalSunrise?.withTimeZoneAdjustment(for: location.timeZone),
			 let nauticalSunset = solar.nauticalSunset?.withTimeZoneAdjustment(for: location.timeZone) {
			let yStart: Double = max(0, solar.startOfDay.distance(to: nauticalSunrise))
			let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: nauticalSunset))
			BarMark(
				x: .value("Nautical Twilight", solar.date, unit: .month),
				yStart: .value("Nautical Sunrise", yStart),
				yEnd: .value("Nautical Sunset", yEnd)
			)
			.foregroundStyle(by: .value("Phase", Solar.Phase.nautical))
		}
	}

	@ChartContentBuilder
	private func civilBarMark(for solar: Solar) -> some ChartContent {
		if let civilSunrise = solar.civilSunrise?.withTimeZoneAdjustment(for: location.timeZone),
			 let civilSunset = solar.civilSunset?.withTimeZoneAdjustment(for: location.timeZone) {
			let yStart: Double = max(0, solar.startOfDay.distance(to: civilSunrise))
			let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: civilSunset))
			BarMark(
				x: .value("Civil Twilight", solar.date, unit: .month),
				yStart: .value("Civil Sunrise", yStart),
				yEnd: .value("Civil Sunset", yEnd)
			)
			.foregroundStyle(by: .value("Phase", Solar.Phase.civil))
		}
	}

	private func daylightBarMark(for solar: Solar) -> some ChartContent {
		let sunrise: Date = solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)
		let sunset: Date = solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone)
		let yStart: Double = max(0, solar.startOfDay.distance(to: sunrise))
		let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: sunset))
		return BarMark(
			x: .value("Daylight", solar.date, unit: .month),
			yStart: .value("Sunrise", yStart),
			yEnd: .value("Sunset", yEnd)
		)
		.foregroundStyle(by: .value("Phase", Solar.Phase.day))
	}

	private var yAxisMarks: some AxisContent {
		let strideValues: [Double] = stride(from: 0.0, through: dayLength, by: 60 * 60 * 4).compactMap { $0 }
		return AxisMarks(values: strideValues) { value in
			AxisTick()
			AxisGridLine()
			AxisValueLabel {
				yAxisLabel(for: value)
			}
		}
	}

	@ViewBuilder
	private func yAxisLabel(for value: AxisValue) -> some View {
		let startOfDay: Date = Date().startOfDay
		if let doubleValue = value.as(Double.self) {
			let date: Date = startOfDay.addingTimeInterval(doubleValue)
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

extension AnnualDaylightChart {
	var monthlySolars: Array<Solar> {
		guard let year = calendar.dateInterval(of: .year, for: timeMachine.date) else {
			return []
		}
		
		var lastDate = calendar.date(bySetting: .day, value: 21, of: year.start) ?? year.start
		lastDate = calendar.date(bySetting: .hour, value: 12, of: lastDate) ?? lastDate
		var dates: Array<Date> = []
		
		while lastDate < year.end {
			dates.append(lastDate)
			lastDate = calendar.date(byAdding: .month, value: 1, to: lastDate) ?? lastDate.addingTimeInterval(60 * 60 * 24 * 7 * 4)
		}
		
		return dates.map { date in
			return Solar(for: date, coordinate: location.coordinate)
		}.compactMap { $0 }
	}
}

struct AnnualDaylightChart_Previews: PreviewProvider {
	static var previews: some View {
		Form {
			AnnualDaylightChart(location: TemporaryLocation.placeholderLondon)
				.frame(minHeight: 300)
			AnnualDaylightChart(location: TemporaryLocation.placeholderGreenland)
				.frame(minHeight: 300)
		}
	}
}
