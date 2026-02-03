//
//  AnnualDaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import SwiftUI
import Charts
import TimeMachine

struct AnnualDaylightChart<Location: AnyLocation>: View {
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	var location: Location

	var kvPairs: KeyValuePairs<NTSolar.Phase, Color> = [
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
		.environment(\.timeZone, location.timeZone)
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
	private func solarBarMarks(for solar: NTSolar) -> some ChartContent {
		astronomicalBarMark(for: solar)
		nauticalBarMark(for: solar)
		civilBarMark(for: solar)
		daylightBarMark(for: solar)
	}

	@ChartContentBuilder
	private func astronomicalBarMark(for solar: NTSolar) -> some ChartContent {
		if let astronomicalSunrise = solar.astronomicalSunrise,
			 let astronomicalSunset = solar.astronomicalSunset {
			let yStart: Double = max(0, solar.startOfDay.distance(to: astronomicalSunrise))
			let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: astronomicalSunset))
			BarMark(
				x: .value("Astronomical Twilight", solar.date, unit: .month),
				yStart: .value("Astronomical Sunrise", yStart),
				yEnd: .value("Astronomical Sunset", yEnd)
			)
			.foregroundStyle(by: .value("Phase", NTSolar.Phase.astronomical))
		}
	}

	@ChartContentBuilder
	private func nauticalBarMark(for solar: NTSolar) -> some ChartContent {
		if let nauticalSunrise = solar.nauticalSunrise,
			 let nauticalSunset = solar.nauticalSunset {
			let yStart: Double = max(0, solar.startOfDay.distance(to: nauticalSunrise))
			let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: nauticalSunset))
			BarMark(
				x: .value("Nautical Twilight", solar.date, unit: .month),
				yStart: .value("Nautical Sunrise", yStart),
				yEnd: .value("Nautical Sunset", yEnd)
			)
			.foregroundStyle(by: .value("Phase", NTSolar.Phase.nautical))
		}
	}

	@ChartContentBuilder
	private func civilBarMark(for solar: NTSolar) -> some ChartContent {
		if let civilSunrise = solar.civilSunrise,
			 let civilSunset = solar.civilSunset {
			let yStart: Double = max(0, solar.startOfDay.distance(to: civilSunrise))
			let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: civilSunset))
			BarMark(
				x: .value("Civil Twilight", solar.date, unit: .month),
				yStart: .value("Civil Sunrise", yStart),
				yEnd: .value("Civil Sunset", yEnd)
			)
			.foregroundStyle(by: .value("Phase", NTSolar.Phase.civil))
		}
	}

	private func daylightBarMark(for solar: NTSolar) -> some ChartContent {
		let sunrise: Date = solar.safeSunrise
		let sunset: Date = solar.safeSunset
		let yStart: Double = max(0, solar.startOfDay.distance(to: sunrise))
		let yEnd: Double = min(dayLength, solar.startOfDay.distance(to: sunset))
		return BarMark(
			x: .value("Daylight", solar.date, unit: .month),
			yStart: .value("Sunrise", yStart),
			yEnd: .value("Sunset", yEnd)
		)
		.foregroundStyle(by: .value("Phase", NTSolar.Phase.day))
	}

	private var yAxisMarks: some AxisContent {
		let strideValues: [Double] = stride(from: 0.0, through: dayLength, by: 60 * 60 * 4).compactMap { $0 }
		return AxisMarks(values: strideValues) { value in
			AxisTick()
			AxisGridLine()
			AxisValueLabel {
				yAxisLabel(for: value)
					.environment(\.timeZone, location.timeZone)
			}
		}
	}

	@ViewBuilder
	private func yAxisLabel(for value: AxisValue) -> some View {
		let startOfDay: Date = Date().startOfDay(in: location.timeZone)
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
	var monthlySolars: Array<NTSolar> {
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
			return NTSolar(for: date, coordinate: location.coordinate, timeZone: location.timeZone)
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
