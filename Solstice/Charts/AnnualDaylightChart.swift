//
//  AnnualDaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import SwiftUI
import SunKit
import Charts
import TimeMachine

struct AnnualDaylightChart<Location: AnyLocation>: View {
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	var location: Location

	var kvPairs: KeyValuePairs<Sun.Phase, Color> = [
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
		ForEach(monthlySolars, id: \.date) { sun in
			solarBarMarks(for: sun)
		}
	}

	@ChartContentBuilder
	private func solarBarMarks(for sun: Sun) -> some ChartContent {
		astronomicalBarMark(for: sun)
		nauticalBarMark(for: sun)
		civilBarMark(for: sun)
		daylightBarMark(for: sun)
	}

	@ChartContentBuilder
	private func astronomicalBarMark(for sun: Sun) -> some ChartContent {
		let astronomicalSunrise = sun.astronomicalSunrise.withTimeZoneAdjustment(for: location.timeZone)
		let astronomicalSunset = sun.astronomicalSunset.withTimeZoneAdjustment(for: location.timeZone)
		let yStart: Double = max(0, astronomicalSunrise.timeIntervalSince(sun.startOfDay))
		let yEnd: Double = min(dayLength, astronomicalSunset.timeIntervalSince(sun.startOfDay))
		BarMark(
			x: .value("Astronomical Twilight", sun.date, unit: .month),
			yStart: .value("Astronomical Sunrise", yStart),
			yEnd: .value("Astronomical Sunset", yEnd)
		)
		.foregroundStyle(by: .value("Phase", Sun.Phase.astronomical))
	}

	@ChartContentBuilder
	private func nauticalBarMark(for sun: Sun) -> some ChartContent {
		let nauticalSunrise = sun.nauticalSunrise.withTimeZoneAdjustment(for: location.timeZone)
		let nauticalSunset = sun.nauticalSunset.withTimeZoneAdjustment(for: location.timeZone)
		let yStart: Double = max(0, nauticalSunrise.timeIntervalSince(sun.startOfDay))
		let yEnd: Double = min(dayLength, nauticalSunset.timeIntervalSince(sun.startOfDay))
		BarMark(
			x: .value("Nautical Twilight", sun.date, unit: .month),
			yStart: .value("Nautical Sunrise", yStart),
			yEnd: .value("Nautical Sunset", yEnd)
		)
		.foregroundStyle(by: .value("Phase", Sun.Phase.nautical))
	}

	@ChartContentBuilder
	private func civilBarMark(for sun: Sun) -> some ChartContent {
		let civilSunrise = sun.civilSunrise.withTimeZoneAdjustment(for: location.timeZone)
		let civilSunset = sun.civilSunset.withTimeZoneAdjustment(for: location.timeZone)
		let yStart: Double = max(0, civilSunrise.timeIntervalSince(sun.startOfDay))
		let yEnd: Double = min(dayLength, civilSunset.timeIntervalSince(sun.startOfDay))
		BarMark(
			x: .value("Civil Twilight", sun.date, unit: .month),
			yStart: .value("Civil Sunrise", yStart),
			yEnd: .value("Civil Sunset", yEnd)
		)
		.foregroundStyle(by: .value("Phase", Sun.Phase.civil))
	}

	private func daylightBarMark(for sun: Sun) -> some ChartContent {
		let sunrise: Date = sun.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)
		let sunset: Date = sun.safeSunset.withTimeZoneAdjustment(for: location.timeZone)
		let yStart: Double = max(0, sunrise.timeIntervalSince(sun.startOfDay))
		let yEnd: Double = min(dayLength, sunset.timeIntervalSince(sun.startOfDay))
		return BarMark(
			x: .value("Daylight", sun.date, unit: .month),
			yStart: .value("Sunrise", yStart),
			yEnd: .value("Sunset", yEnd)
		)
		.foregroundStyle(by: .value("Phase", Sun.Phase.day))
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
	var monthlySolars: Array<Sun> {
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
			return Sun(for: date, coordinate: location.coordinate)
		}
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
