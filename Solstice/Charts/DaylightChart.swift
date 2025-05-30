//
//  DaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import Charts
import Solar
import Suite

struct DaylightChart: View {
	@Environment(\.isLuminanceReduced) var isLuminanceReduced
	@Environment(\.colorScheme) var colorScheme
	
	@State private var selectedEvent: Solar.Event?
	@State private var currentX: Date?
	
	var solar: Solar
	var timeZone: TimeZone
	var showEventTypes = true
	
	var appearance = Appearance.simple
	var includesSummaryTitle = true
	var hideXAxis = false
	var scrubbable = false
	var markSize: CGFloat = 6
	var yScale = -1.5...1.5
	
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
			
			Chart {
				ForEach(solar.events.filter { range.contains($0.date) }) { solarEvent in
					if showEventTypes || !Solar.Phase.plottablePhases.contains(solarEvent.phase) {
						PointMark(
							x: .value("Event Time", solarEvent.date),
							y: .value("Event", yValue(for: solarEvent.date ))
						)
						.foregroundStyle(pointMarkColor(for: solarEvent.phase))
						.opacity(solarEvent.phase == .night
										 || solarEvent.phase == .day
										 || solarEvent.phase == .sunrise
										 || solarEvent.phase == .sunset ? 0 : 1)
						.symbolSize(markSize * .pi * 2)
					}
				}
			}
			.chartYAxis(.hidden)
			.chartYScale(domain: yScale)
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
					// MARK: Basic elements
					Group {
						// MARK: Horizon Line
						Rectangle()
							.fill(.tertiary)
							.frame(width: geo.size.width, height: 1)
							.offset(y: proxy.position(forY: yValue(for: solar.safeSunrise)) ?? 0)
						
						ZStack {
							// MARK: Scrub indicator
							if let currentX {
								// MARK: Scrub bar
								Rectangle()
									.fill(markForegroundColor)
									.frame(width: 2, height: geo.size.height)
									.position(x: proxy.position(forX: currentX) ?? 0, y: geo.size.height / 2)
									.overlay {
										Rectangle()
											.stroke(style: StrokeStyle(lineWidth: 1))
											.fill(.background)
											.frame(width: 2, height: geo.size.height)
											.position(x: proxy.position(forX: currentX) ?? 0, y: geo.size.height / 2)
									}
							}
							
							// MARK: Sun below horizon
							ZStack {
								Circle()
									.fill(markBackgroundColor)
									.overlay {
										Circle()
											.strokeBorder(style: StrokeStyle(lineWidth: max(1, markSize / 4)))
											.fill(markForegroundColor)
									}
									.frame(width: markSize * 2.5, height: markSize * 2.5)
									.position(
										x: proxy.position(forX: plotDate) ?? 0,
										y: proxy.position(forY: yValue(for: plotDate)) ?? 0
									)
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
									.frame(height: geo.size.height - (proxy.position(forY: yValue(for: solar.safeSunrise)) ?? 0))
							}
							
							// MARK: Sun above horizon
							ZStack {
								Circle()
									.fill(markForegroundColor)
									.frame(width: markSize * 2.5, height: markSize * 2.5)
									.position(
										x: proxy.position(forX: plotDate) ?? 0,
										y: proxy.position(forY: yValue(for: plotDate)) ?? 0
									)
									.shadow(color: .secondary.opacity(0.5), radius: 3)
							}
							.mask(alignment: .top) {
								Rectangle()
									.frame(height: proxy.position(forY: yValue(for: solar.safeSunrise)) ?? 0)
							}
						}
					}
					
					// MARK: Scrub hit area
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
			}
			.chartBackground { proxy in
				// MARK: Solar path
				Path { path in
					if let firstPoint = hours.first,
						 let x = proxy.position(forX: firstPoint),
						 let y = proxy.position(forY: yValue(for: firstPoint)) {
						path.move(to: CGPoint(x: x, y: y))
					}
					
					hours.forEach { hour in
						let x = proxy.position(forX: hour) ?? 0
						let y = proxy.position(forY: yValue(for: hour)) ?? 0
						path.addLine(to: CGPoint(x: x, y: y))
					}
					
					if let lastPoint = hours.last,
						 let x = proxy.position(forX: lastPoint),
						 let y = proxy.position(forY: yValue(for: lastPoint)) {
						path.move(to: CGPoint(x: x, y: y))
					}
				}
				.strokedPath(StrokeStyle(lineWidth: markSize, lineCap: .round, lineJoin: .round))
				.fill(.linearGradient(stops: [
					Gradient.Stop(color: .secondary.opacity(0), location: 0),
					Gradient.Stop(color: .secondary.opacity(0.2), location: 2 / 6),
					Gradient.Stop(color: .secondary.opacity(0.6), location: 1),
				], startPoint: .bottom, endPoint: .top))
			}
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
}

extension DaylightChart {
	var relativeEventTimeString: String {
		if let selectedEvent,
			 calendar.isDateInToday(selectedEvent.date) {
			return " (\((selectedEvent.date..<solar.date.withTimeZoneAdjustment(for: timeZone)).formatted(.timeDuration))"
		}
		return ""
	}
	
	var hours: Array<Date> {
		stride(from: range.lowerBound, through: range.upperBound, by: 60 * 30).compactMap { $0 }
	}
	
	var startOfDay: Date { range.lowerBound }
	var endOfDay: Date { range.upperBound }
	var dayLength: TimeInterval { .twentyFourHours }
	
	var noonish: Date { startOfDay.addingTimeInterval(TimeInterval.twentyFourHours / 2) }
	
	var culminationDelta: TimeInterval { solar.solarNoon?.distance(to: noonish) ?? 0 }
	
	var daylightProportion: Double {
		solar.daylightDuration / dayLength
	}
	
	func pointMarkColor(for eventPhase: Solar.Phase) -> HierarchicalShapeStyle {
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
	
	func progressValue(for date: Date) -> Double {
		return (date.distance(to: startOfDay) - culminationDelta) / dayLength
	}
	
	func yValue(for date: Date) -> Double {
		return sin(progressValue(for: date) * .pi * 2 - .pi / 2)
	}
	
	func scrub(to point: CGPoint, in geo: GeometryProxy, proxy: ChartProxy) {
		var start: Double = 0
		
		if #available(iOS 17, macOS 14, watchOS 10, visionOS 1.0, *) {
			if let plotFrame = proxy.plotFrame {
				start = geo[plotFrame].origin.x
			}
		} else {
			start = geo[proxy.plotAreaFrame].origin.x
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
				return "Simple"
			case .graphical:
				return "Graphical"
			}
		}
	}
}

#Preview {
	Form {
		Group {
			DaylightChart(
				solar: Solar(coordinate: TemporaryLocation.placeholderLondon.coordinate)!,
				timeZone: TimeZone.autoupdatingCurrent,
				scrubbable: true
			)
			
			DaylightChart(
				solar: Solar(coordinate: TemporaryLocation.placeholderLondon.coordinate)!,
				timeZone: TimeZone.autoupdatingCurrent,
				appearance: .graphical,
				scrubbable: true
			)
			.listRowBackground(Color.clear)
		}
		.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
	}
}
