//
//  DaylightChart.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import Charts
import Solar
import Charts
import CoreLocation

func mapRange(_ value: Double, minX: Double, maxX: Double, minY: Double, maxY: Double) -> Double {
	return minY + (maxY - minY) * ((value - minX) / (maxX - minX))
}

struct DaylightChart: View {
	var solar: Solar
	var timeZone: TimeZone
	
	@State private var selectedEvent: Solar.Event?
	@State private var currentX: Date?
	
	var body: some View {
		VStack(alignment: .leading) {
			VStack(alignment: .leading) {
				Text(solar.differenceString)
					.font(.title2)
					.fontWeight(.semibold)
					.opacity(selectedEvent == nil ? 1 : 0)
					.overlay(alignment: .leading) {
						if let selectedEvent {
							VStack(alignment: .leading) {
								Text(selectedEvent.label)
									.foregroundStyle(.secondary)
								Text("\(selectedEvent.date, style: .time)")
									.font(.title2)
							}
						}
					}
			}
			.padding()
			.fontDesign(.rounded)
			.fontWeight(.semibold)
			
			TimelineView(.everyMinute) { time in
				Chart {
					ForEach(solarEvents) { solarEvent in
						if solarEvent.phase != .currentTime {
							PointMark(
								x: .value("Event Time", solarEvent.date ),
								y: .value("Event", yValue(for: solarEvent.date ))
							)
							.foregroundStyle(pointMarkColor(for: solarEvent.phase))
							.opacity(solarEvent.phase == .night
											 || solarEvent.phase == .day
											 || solarEvent.phase == .sunrise
											 || solarEvent.phase == .sunset ? 0 : 1)
						}
					}
				}
				.chartYAxis(.hidden)
				.chartYScale(domain: -1.2...1.2)
				.chartXScale(domain: solar.startOfDay...solar.endOfDay)
				.chartOverlay { proxy in
					GeometryReader { geo in
						ZStack {
							ZStack {
								Circle()
									.fill(.background)
									.overlay {
										Circle()
											.strokeBorder(style: StrokeStyle(lineWidth: 2))
											.fill(.primary)
									}
									.frame(width: 20, height: 20)
									.position(
										x: proxy.position(forX: timeZoneAdjustedDate) ?? 0,
										y: proxy.position(forY: yValue(for: timeZoneAdjustedDate)) ?? 0
									)
									.shadow(color: .secondary.opacity(0.5), radius: 8)
							}
							.background(.background.opacity(0.2))
							.mask(alignment: .bottom) {
								Rectangle()
									.frame(height: geo.size.height - (proxy.position(forY: yValue(for: solar.safeSunrise.addingTimeInterval(totalTimeZoneOffset))) ?? 0))
							}
							
							ZStack {
								Circle()
									.fill(.primary)
									.frame(width: 20, height: 20)
									.position(
										x: proxy.position(forX: timeZoneAdjustedDate) ?? 0,
										y: proxy.position(forY: yValue(for: timeZoneAdjustedDate)) ?? 0
									)
									.shadow(color: .secondary.opacity(0.5), radius: 8)
							}
							.mask(alignment: .top) {
								Rectangle()
									.frame(height: proxy.position(forY: yValue(for: solar.safeSunrise.addingTimeInterval(totalTimeZoneOffset))) ?? 0)
							}
						}
						
						Rectangle()
						#if !os(watchOS)
							.fill(.regularMaterial)
						#endif
							.frame(width: geo.size.width, height: 2)
							.offset(y: proxy.position(forY: yValue(for: solar.safeSunrise.addingTimeInterval(totalTimeZoneOffset))) ?? 0)
						
						if let selectedEvent {
							Rectangle()
								.fill(.primary)
								.frame(width: 2, height: geo.size.height)
								.position(x: proxy.position(forX: selectedEvent.date) ?? 0, y: geo.size.height / 2)
								.overlay {
									Rectangle()
										.stroke(style: StrokeStyle(lineWidth: 1))
										.fill(.background)
										.frame(width: 2, height: geo.size.height)
										.position(x: proxy.position(forX: selectedEvent.date) ?? 0, y: geo.size.height / 2)
								}
						}
						
						Rectangle()
							.fill(Color.clear)
							.contentShape(Rectangle())
							.gesture(DragGesture()
								.onChanged { value in
									let start = geo[proxy.plotAreaFrame].origin.x
									let xCurrent = value.location.x - start
									
									if let date: Date = proxy.value(atX: xCurrent),
										 let nearestEvent = solarEvents.first(where: { abs($0.date.distance(to: date)) < 60 * 30 && $0.phase != .currentTime }){
										selectedEvent = nearestEvent
									}
								}
								.onEnded { _ in
									selectedEvent = nil
								})
					}
				}
				.chartBackground { proxy in
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
					.strokedPath(StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
					.fill(.linearGradient(stops: [
						Gradient.Stop(color: .secondary.opacity(0), location: 0),
						Gradient.Stop(color: .secondary.opacity(0.2), location: 2 / 6),
						Gradient.Stop(color: .secondary.opacity(0.6), location: 1),
					], startPoint: .bottom, endPoint: .top))
				}
				.foregroundStyle(.primary)
			}
		}
	}
	
}

extension DaylightChart {
	var formatter: RelativeDateTimeFormatter {
		let formatter = RelativeDateTimeFormatter()
		return formatter
	}
	
	var relativeEventTimeString: String {
		if let selectedEvent,
			 Calendar.autoupdatingCurrent.isDateInToday(selectedEvent.date) {
			return " (\(formatter.localizedString(for: selectedEvent.date, relativeTo: solar.date.addingTimeInterval(locationTimeZoneOffset))))"
		}
		return ""
	}
	
	var timeZoneAdjustedDate: Date {
		solar.date.addingTimeInterval(totalTimeZoneOffset)
	}
	
	var locationTimeZoneOffset: TimeInterval {
		TimeInterval(timeZone.secondsFromGMT(for: solar.date)) - timeZone.daylightSavingTimeOffset(for: solar.date)
	}
	
	var localTimeZoneOffset: TimeInterval {
		TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT(for: solar.date)) - TimeZone.autoupdatingCurrent.daylightSavingTimeOffset(for: solar.date)
	}
	
	var totalTimeZoneOffset: TimeInterval {
		localTimeZoneOffset + locationTimeZoneOffset
	}
	
	var solarEvents: Array<Solar.Event> {
		solar.events.map { event in
			Solar.Event(label: event.label,
									date: event.date.addingTimeInterval(totalTimeZoneOffset),
									phase: event.phase)
		}
		.compactMap { $0 }
	}
	
	var hours: Array<Date> {
		stride(from: solar.startOfDay, through: solar.endOfDay, by: 60 * 30).compactMap { $0 }
	}
	
	var startOfDay: Date { solar.startOfDay.addingTimeInterval(totalTimeZoneOffset) }
	var endOfDay: Date { solar.endOfDay.addingTimeInterval(totalTimeZoneOffset) }
	var dayLength: TimeInterval { startOfDay.distance(to: endOfDay) }
	
	var noonish: Date { startOfDay.addingTimeInterval(dayLength / 2) }
	
	var culminationDelta: TimeInterval { solar.peak.addingTimeInterval(totalTimeZoneOffset).distance(to: noonish) }
	
	var daylightProportion: Double { solar.daylightDuration / dayLength }
	
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
		selectedEvent = solarEvents.filter {
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
}

struct DaylightChart_Previews: PreviewProvider {
	static var previews: some View {
		DaylightChart(solar: Solar(coordinate: CLLocationCoordinate2D(latitude: 51.50998, longitude: -0.1337))!, timeZone: .autoupdatingCurrent)
	}
}
