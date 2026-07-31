//
//  DaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Charts
import Suite
import SwiftUI
import TimeMachine

struct DaylightChart: View {
	@Environment(\.isLuminanceReduced) var isLuminanceReduced
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.timeMachine) private var timeMachine

	@State private var selectedEvent: NTSolar.Event?
	@State private var currentX: TimeInterval?
	/// Tracks the sun marker's current position. Updated instantly during time travel
	/// and animated along the solar path on reset.
	@State private var sunDisplayOffset: TimeInterval = 0

	var solar: NTSolar
	var timeZone: TimeZone
	var showEventTypes = true

	var appearance = Appearance.simple
	var includesSummaryTitle = true
	var hideXAxis = false
	var scrubbable = false
	var markSize: CGFloat = 6
	var yScale: ClosedRange<Double>? = nil
	/// Whether to publish `SkyChartGeometryPreferenceKey` for a `SkyGradient` background. Only the
	/// container that defines the `skyGradient` coordinate space should opt in — resolving the
	/// named space in a hierarchy that lacks it logs a runtime warning on every evaluation.
	var tracksSkyGeometry = false

	/// The date to highlight — uses scrubbable position when dragging, otherwise the solar date.
	var plotDate: Date {
		if let currentX {
			return midnight.addingTimeInterval(currentX)
		}
		return solar.date
	}

	/// Offset of `plotDate` from midnight, used for x-axis position lookups.
	var plotOffset: TimeInterval {
		plotDate.timeIntervalSince(midnight)
	}

	/// Midnight of `solar.date` in the chart's time zone.
	var midnight: Date {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		return calendar.startOfDay(for: solar.date)
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

	/// X-axis domain: always a full 24-hour day expressed as seconds from midnight.
	/// Keeping this constant means only the y-axis animates when the date changes.
	var range: ClosedRange<TimeInterval> {
		0 ... 86400
	}

	var body: some View {
		VStack(alignment: .leading) {
			if includesSummaryTitle {
				DaylightSummaryTitle(solar: solar, event: selectedEvent, date: currentX.map { midnight.addingTimeInterval($0) }, timeZone: timeZone)
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
		.preference(key: DaylightGradientTimePreferenceKey.self, value: plotDate)
	}

	private var chartContent: some View {
		Chart {
			let hours = hours
			let altitudes = sampledAltitudes
			ForEach(hours.indices, id: \.self) { index in
				LineMark(
					x: .value("Time", hours[index]),
					y: .value("Altitude", altitudes[index])
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
				AxisMarks(values: .stride(by: 6.0 * 3600.0)) { value in
					AxisGridLine()
					AxisTick()
					AxisValueLabel {
						if let offset = value.as(TimeInterval.self) {
							Text(midnight.addingTimeInterval(offset), format: Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone))
						}
					}
				}
			}
		}
		.chartXScale(domain: range)
		.chartOverlay { proxy in
			GeometryReader { geo in
				chartOverlayContent(proxy: proxy, geo: geo)
			}
		}
		// Plot the chart left-to-right in every locale. The sun marker, scrub
		// indicator, and drag hit-testing are positioned manually via
		// `ChartProxy.position(forX:)` in an LTR coordinate space, but SwiftUI
		// Charts auto-mirrors the line, points, and axis under RTL locales. That
		// mismatch left the sun detached from the path (e.g. in Arabic). Pinning
		// the plot to LTR keeps the native marks and the overlay in one coordinate
		// system; the summary title and surrounding UI still follow the locale.
		.environment(\.layoutDirection, .leftToRight)
		.animation(timeMachine.isActive ? nil : .smooth(duration: 0.5), value: solar.date)
		.onAppear {
			sunDisplayOffset = plotOffset
		}
		.onChange(of: currentX) { _, _ in
			sunDisplayOffset = currentX ?? plotOffset
		}
		.onChange(of: solar.date) { oldDate, _ in
			if timeMachine.isActive {
				sunDisplayOffset = plotOffset
			} else {
				// On reset: animate the sun along the new day's solar path from
				// the old time position to the current time position.
				var cal = Calendar.current
				cal.timeZone = timeZone
				let oldMidnight = cal.startOfDay(for: oldDate)
				sunDisplayOffset = oldDate.timeIntervalSince(oldMidnight)
				withAnimation(.smooth(duration: 0.5)) {
					sunDisplayOffset = plotOffset
				}
			}
		}
	}

	private var filteredEvents: [NTSolar.Event] {
		solar.events.filter { range.contains(eventOffset(for: $0.date)) }
	}

	private func eventPointMark(for solarEvent: NTSolar.Event) -> some ChartContent {
		let offset = eventOffset(for: solarEvent.date)
		return PointMark(
			x: .value("Event Time", offset),
			y: .value("Event", yValue(for: offset))
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

		horizonLine(width: geo.size.width, yOffset: horizonY)

		ZStack {
			scrubIndicator(proxy: proxy, geoHeight: geo.size.height)
			sunBelowHorizon(proxy: proxy, geo: geo, horizonY: horizonY)
			sunAboveHorizon(proxy: proxy, horizonY: horizonY)
		}

		scrubHitArea(geo: geo, proxy: proxy)

		// Report the sun marker and horizon line so a SkyGradient background can align with them.
		if tracksSkyGeometry {
			Color.clear
				.preference(key: SkyChartGeometryPreferenceKey.self, value: skyGeometry(proxy: proxy, geo: geo))
		}
	}

	/// The sun marker's position and the horizon line's y, expressed in the shared `skyGradient`
	/// coordinate space.
	private func skyGeometry(proxy: ChartProxy, geo: GeometryProxy) -> SkyChartGeometry {
		let frame = geo.frame(in: .named(SkyGradient.coordinateSpaceName))
		var geometry = SkyChartGeometry()

		if let sunX = proxy.position(forX: sunDisplayOffset),
		   let sunY = proxy.position(forY: yValue(for: sunDisplayOffset))
		{
			geometry.sunPoint = CGPoint(x: frame.minX + sunX, y: frame.minY + sunY)
		}

		if let horizonY = proxy.position(forY: 0.0) {
			geometry.horizonY = frame.minY + horizonY
		}

		return geometry
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
			RoundedRectangle(cornerRadius: 8)
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
		let sunX: CGFloat = proxy.position(forX: sunDisplayOffset) ?? 0
		let sunY: CGFloat = proxy.position(forY: yValue(for: sunDisplayOffset)) ?? 0
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
			// In simple appearance the chart sits on a plain background, so a subtle veil marks the
			// below-horizon region. In graphical appearance the SkyGradient mesh renders the ground
			// itself (see SkyModel.mesh(horizonFraction:)) — anything painted here would darken the
			// chart's own marks and stop short of the background's edges.
			if appearance == .simple {
				Rectangle()
					.fill(.clear)
					.background(.background.opacity(isLuminanceReduced ? 0 : 0.3))
					.mask {
						LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
					}
					.blendMode(.overlay)
			}
		}
		.mask(alignment: .bottom) {
			Rectangle()
				.frame(height: belowHorizonHeight)
		}
	}

	private func sunAboveHorizon(proxy: ChartProxy, horizonY: CGFloat) -> some View {
		let sunX: CGFloat = proxy.position(forX: sunDisplayOffset) ?? 0
		let sunY: CGFloat = proxy.position(forY: yValue(for: sunDisplayOffset)) ?? 0

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
						case let .active(point):
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
	var hours: [TimeInterval] {
		stride(from: range.lowerBound, through: range.upperBound, by: 60 * 30).map { $0 }
	}

	var startOfDay: Date {
		midnight
	}

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
		}.sorted(by: { a, _ in
			a.date.compare(.now) == .orderedDescending
		}).first
	}

	/// The y-scale to use for the chart, fitted to the actual min/max altitudes
	/// across all sampled hours with padding so the path never crowds the edges.
	/// Callers may override via the `yScale` property.
	private var effectiveYScale: ClosedRange<Double> {
		if let yScale { return yScale }
		let altitudes = sampledAltitudes
		guard let minAlt = altitudes.min(), let maxAlt = altitudes.max() else {
			return -90.0 ... 90.0
		}
		let span = maxAlt - minAlt
		let padding = span * 0.1
		return (minAlt - padding) ... (maxAlt + padding)
	}

	/// The sun's actual altitude in degrees at the given offset (seconds from midnight).
	/// 0° is the geometric horizon; positive = above, negative = below.
	func yValue(for offset: TimeInterval) -> Double {
		solar.altitude(at: midnight.addingTimeInterval(offset))
	}

	/// Altitude for every sampled hour. Memoized because the body re-evaluates every frame during
	/// scrubbing and time travel while the sampled day and place rarely change.
	private var sampledAltitudes: [Double] {
		let key = AltitudeSamplesKey(midnight: midnight,
		                             latitude: Int((solar.coordinate.latitude * 1e4).rounded()),
		                             longitude: Int((solar.coordinate.longitude * 1e4).rounded()))
		return altitudeSamplesCache.value(for: key) {
			hours.map { yValue(for: $0) }
		}
	}

	/// Seconds from midnight of `solar.date` to the given event date.
	func eventOffset(for date: Date) -> TimeInterval {
		date.timeIntervalSince(midnight)
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
		   	abs(eventOffset(for: lhs.date) - currentX) <= abs(eventOffset(for: rhs.date) - currentX)
		   }).first
		{
			selectedEvent = nearestEvent
		}
	}
}

private struct AltitudeSamplesKey: Hashable {
	let midnight: Date
	let latitude: Int
	let longitude: Int
}

private let altitudeSamplesCache = SkyRenderCache<AltitudeSamplesKey, [Double]>(capacity: 16)

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
