//
//  DaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import Charts
import Suite

struct DaylightChart: View {
	@Environment(\.isLuminanceReduced) var isLuminanceReduced
	@Environment(\.colorScheme) var colorScheme

	@State private var selectedEvent: NTSolar.Event?
	@State private var currentX: Date?

	var solar: NTSolar
	var timeZone: TimeZone
	var showEventTypes = true

	var appearance = Appearance.simple
	var includesSummaryTitle = true
	var hideXAxis = false
	var scrubbable = false
	var markSize: CGFloat = 6
	var yScale: ClosedRange<Double>? = nil

	var plotDate: Date {
		currentX ?? solar.date
	}
	
	var markForegroundColor: Color {
		if appearance == .graphical {
			return .white
		} else {
			return colorScheme == .dark ? .white : .black
		}
	}
	
	var markBackgroundColor: Color {
		if appearance == .graphical {
			return .black
		} else {
			return colorScheme == .dark ? .black : .white
		}
	}
	
	var range: ClosedRange<Date> {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		
		let startOfDay = calendar.startOfDay(for: solar.date)
		let endOfDay = max(solar.safeSunset, calendar.date(byAdding: DateComponents(day: 1), to: startOfDay) ?? solar.date)
		return startOfDay...endOfDay
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			if includesSummaryTitle {
				DaylightSummaryTitle(solar: solar, event: selectedEvent, date: currentX, timeZone: timeZone)
			}

			chartContent
				.frame(maxHeight: 500)
				.foregroundStyle(.primary)
				.if(!hideXAxis && !IS_WIDGET_TARGET) { view in
					view.padding(.bottom)
				}
		}
		.foregroundStyle(markForegroundColor)
		.if(appearance == .graphical) { view in
			view
				.blendMode(.plusLighter)
				.environment(\.colorScheme, .dark)
		}
		.environment(\.timeZone, timeZone)
		.preference(key: DaylightGradientTimePreferenceKey.self, value: currentX ?? solar.date)
	}

	private var chartContent: some View {
		Chart {
			ForEach(hours, id: \.self) { hour in
				LineMark(
					x: .value("Time", hour),
					y: .value("Altitude", yValue(for: hour))
				)
				.interpolationMethod(.catmullRom)
				.foregroundStyle(solarPathGradient)
				.lineStyle(StrokeStyle(lineWidth: markSize, lineCap: .round, lineJoin: .round))
			}

			ForEach(filteredEvents, id: \.id) { solarEvent in
				eventPointMark(for: solarEvent)
			}
		}
		.chartLegend(.hidden)
		.chartYAxis(.hidden)
		.chartYScale(domain: effectiveYScale)
		.chartXAxis(hideXAxis ? .hidden : .automatic)
		.chartXAxis {
			if !hideXAxis {
				AxisMarks(format: Date.FormatStyle(
					date: .omitted,
					time: .shortened,
					timeZone: timeZone
				))
			}
		}
		.chartXScale(domain: range)
		.chartOverlay { proxy in
			GeometryReader { geo in
				chartOverlayContent(proxy: proxy, geo: geo)
			}
		}
		.animation(nil, value: solar.date)
	}

	private var filteredEvents: [NTSolar.Event] {
		solar.events.filter { range.contains($0.date) }
	}

	private func eventPointMark(for solarEvent: NTSolar.Event) -> some ChartContent {
		PointMark(
			x: .value("Event Time", solarEvent.date),
			y: .value("Event", yValue(for: solarEvent.date))
		)
		.foregroundStyle(pointMarkColor(for: solarEvent.phase))
		.opacity(eventPointOpacity(for: solarEvent.phase))
		.symbolSize(markSize * .pi * 2)
	}

	private func eventPointOpacity(for phase: NTSolar.Phase) -> Double {
		let hiddenPhases: Set<NTSolar.Phase> = [.night, .day, .sunrise, .sunset]
		let shouldShow: Bool = showEventTypes || !NTSolar.Phase.plottablePhases.contains(phase)
		return (shouldShow && !hiddenPhases.contains(phase)) ? 1 : 0
	}

	@ViewBuilder
	private func chartOverlayContent(proxy: ChartProxy, geo: GeometryProxy) -> some View {
		let horizonY: CGFloat = proxy.position(forY: 0.0) ?? 0

		Group {
			horizonLine(width: geo.size.width, yOffset: horizonY)

			ZStack {
				scrubIndicator(proxy: proxy, geoHeight: geo.size.height)
				sunBelowHorizon(proxy: proxy, geo: geo, horizonY: horizonY)
				sunAboveHorizon(proxy: proxy, horizonY: horizonY)
			}
		}
		.animation(nil, value: solar.date)

		scrubHitArea(geo: geo, proxy: proxy)
	}

	private func horizonLine(width: CGFloat, yOffset: CGFloat) -> some View {
		Rectangle()
			.fill(.tertiary)
			.frame(width: width, height: 1)
			.offset(y: yOffset)
	}

	@ViewBuilder
	private func scrubIndicator(proxy: ChartProxy, geoHeight: CGFloat) -> some View {
		if let currentX {
			let xPos: CGFloat = proxy.position(forX: currentX) ?? 0
			Rectangle()
				.fill(markForegroundColor)
				.frame(width: 2, height: geoHeight)
				.position(x: xPos, y: geoHeight / 2)
				.overlay {
					Rectangle()
						.stroke(style: StrokeStyle(lineWidth: 1))
						.fill(.background)
						.frame(width: 2, height: geoHeight)
						.position(x: xPos, y: geoHeight / 2)
				}
		}
	}

	private func sunBelowHorizon(proxy: ChartProxy, geo: GeometryProxy, horizonY: CGFloat) -> some View {
		let sunX: CGFloat = proxy.position(forX: plotDate) ?? 0
		let sunY: CGFloat = proxy.position(forY: yValue(for: plotDate)) ?? 0
		let belowHorizonHeight: CGFloat = geo.size.height - horizonY

		return ZStack {
			Circle()
				.fill(markBackgroundColor)
				.overlay {
					Circle()
						.strokeBorder(style: StrokeStyle(lineWidth: max(1, markSize / 4)))
						.fill(markForegroundColor)
				}
				.frame(width: markSize * 2.5, height: markSize * 2.5)
				.position(x: sunX, y: sunY)
				.shadow(color: .secondary.opacity(0.5), radius: 2)
				.blendMode(.normal)
		}
		.background {
			Rectangle()
				.fill(.clear)
				.background(.background.opacity(isLuminanceReduced ? 0 : 0.3))
				.mask {
					LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
				}
				.blendMode(.overlay)
		}
		.mask(alignment: .bottom) {
			Rectangle()
				.frame(height: belowHorizonHeight)
		}
	}

	private func sunAboveHorizon(proxy: ChartProxy, horizonY: CGFloat) -> some View {
		let sunX: CGFloat = proxy.position(forX: plotDate) ?? 0
		let sunY: CGFloat = proxy.position(forY: yValue(for: plotDate)) ?? 0

		return ZStack {
			Circle()
				.fill(markForegroundColor)
				.frame(width: markSize * 2.5, height: markSize * 2.5)
				.position(x: sunX, y: sunY)
				.shadow(color: .secondary.opacity(0.5), radius: 3)
		}
		.mask(alignment: .top) {
			Rectangle()
				.frame(height: horizonY)
		}
	}

	private func scrubHitArea(geo: GeometryProxy, proxy: ChartProxy) -> some View {
		Color.clear
			.contentShape(Rectangle())
			.if(scrubbable) { view in
				view
#if os(iOS)
					.gesture(DragGesture()
						.onChanged { value in
							scrub(to: value.location, in: geo, proxy: proxy)
						}
						.onEnded { _ in
							selectedEvent = nil
							currentX = nil
						})
#elseif os(macOS)
					.onContinuousHover { value in
						switch value {
						case .active(let point):
							scrub(to: point, in: geo, proxy: proxy)
						case .ended:
							selectedEvent = nil
							currentX = nil
						}
					}
#endif
			}
	}

	private var solarPathGradient: LinearGradient {
		LinearGradient(stops: [
			Gradient.Stop(color: .secondary.opacity(0), location: 0),
			Gradient.Stop(color: .secondary.opacity(0.2), location: 2 / 6),
			Gradient.Stop(color: .secondary.opacity(0.6), location: 1),
		], startPoint: .bottom, endPoint: .top)
	}
}

extension DaylightChart {
	var hours: Array<Date> {
		stride(from: range.lowerBound, through: range.upperBound, by: 60 * 30).compactMap { $0 }
	}

	var startOfDay: Date { range.lowerBound }

	func pointMarkColor(for eventPhase: NTSolar.Phase) -> HierarchicalShapeStyle {
		switch eventPhase {
		case .astronomical:
			return .quaternary
		case .nautical:
			return .tertiary
		case .civil:
			return .secondary
		default:
			return .primary
		}
	}

	func resetSelectedEvent() {
		selectedEvent = solar.events.filter {
			$0.phase == .sunset || $0.phase == .sunrise
		}.sorted(by: { a, b in
			a.date.compare(.now) == .orderedDescending
		}).first
	}

	/// The y-scale to use for the chart, fitted to the actual min/max altitudes
	/// across all sampled hours with padding so the path never crowds the edges.
	/// Callers may override via the `yScale` property.
	private var effectiveYScale: ClosedRange<Double> {
		if let yScale { return yScale }
		let altitudes = hours.map { yValue(for: $0) }
		guard let minAlt = altitudes.min(), let maxAlt = altitudes.max() else {
			return -90.0...90.0
		}
		let span = maxAlt - minAlt
		let padding = span * 0.1
		return (minAlt - padding)...(maxAlt + padding)
	}

	/// The sun's actual altitude in degrees at `date` for the current solar.
	/// 0° is the geometric horizon; positive = above, negative = below.
	func yValue(for date: Date) -> Double {
		solar.altitude(at: date)
	}

	func scrub(to point: CGPoint, in geo: GeometryProxy, proxy: ChartProxy) {
		var start: Double = 0
		
		if let plotFrame = proxy.plotFrame {
			start = geo[plotFrame].origin.x
		}

		let xCurrent = point.x - start
		
		currentX = proxy.value(atX: xCurrent)
		
		if let currentX,
			 let nearestEvent = solar.events.sorted(by: { lhs, rhs in
				 abs(lhs.date.distance(to: currentX)) <= abs(rhs.date.distance(to: currentX))
			 }).first {
			selectedEvent = nearestEvent
		}
	}
}

extension DaylightChart {
	enum Appearance: String, Codable, CaseIterable {
		case simple = "Simple",
				 graphical = "Graphical"
		
		var description: LocalizedStringKey {
			switch self {
			case .simple:
				return "Monochrome"
			case .graphical:
				return "Graphical"
			}
		}
		
		var tintColor: Color {
			switch self {
			case .simple: return .primary
			case .graphical: return .accent
			}
		}
	}
}

#Preview {
	Form {
		Group {
			DaylightChart(
				solar: NTSolar(for: .now, coordinate: TemporaryLocation.placeholderLondon.coordinate, timeZone: TemporaryLocation.placeholderLondon.timeZone)!,
				timeZone: TimeZone.autoupdatingCurrent,
				scrubbable: true
			)
			
			DaylightChart(
				solar: NTSolar(for: .now, coordinate: TemporaryLocation.placeholderLondon.coordinate, timeZone: TemporaryLocation.placeholderLondon.timeZone)!,
				timeZone: TimeZone.autoupdatingCurrent,
				appearance: .graphical,
				scrubbable: true
			)
			.listRowBackground(Color.clear)
		}
		.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
	}
}
