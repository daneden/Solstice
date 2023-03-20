//
//  Solar+SolarEvent.swift
//  Solstice
//
//  Created by Daniel Eden on 14/02/2023.
//

import Foundation
import Solar
import Charts

extension Solar {
	struct Event: Hashable, Identifiable {
		var id: Int { hashValue }
		let label: String
		var date: Date
		let phase: Phase
		
		init?(label: String, date: Date?, phase: Phase) {
			guard let date else { return nil }
			self.label = label
			self.date = date
			self.phase = phase
		}
		
		var imageName: String {
			switch phase {
			case .sunrise:
				return "sunrise"
			case .sunset:
				return "sunset"
			default:
				return "sun.max"
			}
		}
		
		var description: String {
			phase.rawValue
		}
	}
	
	enum Phase: String, Plottable, CaseIterable {
		case night = "Night",
				 astronomical = "Astronomical Twilight",
				 nautical = "Nautical Twilight",
				 civil = "Civil Twilight",
				 day = "Day",
				 sunrise = "Sunrise",
				 sunset = "Sunset"
	}
	
	var startOfDay: Date {
		calendar.startOfDay(for: date)
	}
	
	var endOfDay: Date {
		var components = DateComponents()
		components.day = 1
		components.nanosecond = -1
		return calendar.date(byAdding: components, to: startOfDay) ?? date
	}
	
	private var culmination: Date {
		let halfDistance = abs(safeSunset.distance(to: safeSunrise)) / 2
		return safeSunrise.addingTimeInterval(halfDistance)
	}
	
	var events: Array<Event> {
		[
			Event(label: "Astronomical Sunrise", date: astronomicalSunrise, phase: .astronomical),
			Event(label: "Nautical Sunrise", date: nauticalSunrise, phase: .nautical),
			Event(label: "Civil Sunrise", date: civilSunrise, phase: .civil),
			Event(label: "Sunrise", date: safeSunrise, phase: .sunrise),
			Event(label: "Culmination", date: culmination, phase: .day),
			Event(label: "Sunset", date: safeSunset, phase: .sunset),
			Event(label: "Civil Sunset", date: civilSunset, phase: .civil),
			Event(label: "Nautical Sunset", date: nauticalSunset, phase: .nautical),
			Event(label: "Astronomical Sunset", date: astronomicalSunset, phase: .astronomical),
		]
			.compactMap { $0 }
			.sorted { a, b in
				a.date.compare(b.date) == .orderedAscending
			}
	}
}
