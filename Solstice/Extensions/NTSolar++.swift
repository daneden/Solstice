//
//  NTSolar++.swift
//  Solstice
//
//  Created by Daniel Eden on 03/02/2026.
//

import Foundation
import SwiftUI
import Charts
import CoreLocation

// MARK: - Solar Event Types
extension NTSolar {
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

		static let plottablePhases: [Phase] = [.astronomical, .nautical, .civil]
	}

	var phases: [Phase: (sunrise: Date?, sunset: Date?)] {
		[
			.astronomical: (astronomicalSunrise, astronomicalSunset),
			.nautical: (nauticalSunrise, nauticalSunset),
			.civil: (civilSunrise, civilSunset),
			.day: (safeSunrise, safeSunset)
		]
	}
}

// MARK: - Day Boundaries
extension NTSolar {
	var startOfDay: Date {
		calendar.startOfDay(for: date)
	}

	var endOfDay: Date {
		var components = DateComponents()
		components.day = 1
		guard let endOfDay = calendar.date(byAdding: components, to: startOfDay) else { return date }
		return endOfDay
	}

	private var culmination: Date {
		let halfDistance = abs(safeSunset.distance(to: safeSunrise)) / 2
		return safeSunrise.addingTimeInterval(halfDistance)
	}
}

// MARK: - Safe Sunrise/Sunset
extension NTSolar {
	var fallbackSunrise: Date? {
		sunrise ?? civilSunrise ?? nauticalSunrise ?? astronomicalSunrise
	}

	var fallbackSunset: Date? {
		sunset ?? civilSunset ?? nauticalSunset ?? astronomicalSunset
	}

	var safeSunrise: Date {
		if let sunrise {
			return sunrise
		}

		if daylightDuration <= 0 {
			return startOfDay.addingTimeInterval(.twentyFourHours / 2)
		} else if daylightDuration >= .twentyFourHours {
			return endOfDay
		}

		return fallbackSunrise ?? startOfDay
	}

	var safeSunset: Date {
		if let sunset {
			return sunset
		}

		if daylightDuration <= 0 {
			return startOfDay.addingTimeInterval(.twentyFourHours / 2)
		} else if daylightDuration >= .twentyFourHours {
			return endOfDay
		}

		return fallbackSunset ?? endOfDay
	}

	var daylightDuration: TimeInterval {
		if let sunrise, let sunset {
			return sunrise.distance(to: sunset)
		}

		guard coordinate.insidePolarCircle else {
			return safeSunrise.distance(to: safeSunset)
		}

		let month = calendar.component(.month, from: date)

		switch month {
		case 1...3, 10...12:
			return coordinate.insideArcticCircle ? 0 : TimeInterval.twentyFourHours
		default:
			return coordinate.insideArcticCircle ? TimeInterval.twentyFourHours : 0
		}
	}
}

// MARK: - Related Days
extension NTSolar {
	var yesterday: NTSolar? {
		let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(60 * 60 * 24 - 1)
		return NTSolar(for: yesterdayDate, coordinate: coordinate, timeZone: timeZone, calendar: calendar)
	}

	var tomorrow: NTSolar? {
		guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else {
			return nil
		}

		return NTSolar(for: tomorrow, coordinate: coordinate, timeZone: timeZone, calendar: calendar)
	}
}

// MARK: - Difference Strings
extension NTSolar {
	var compactDifferenceString: LocalizedStringKey {
		let comparator = date.isToday ? yesterday : NTSolar(for: Date(), coordinate: self.coordinate, timeZone: timeZone, calendar: calendar)
		let difference = daylightDuration - (comparator?.daylightDuration ?? 0)
		let differenceString = Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2))

		let moreOrLess = difference >= 0 ? "+" : "-"

		return LocalizedStringKey("\(moreOrLess)\(differenceString)")
	}

	var differenceString: LocalizedStringKey {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = true
		formatter.dateStyle = .medium
		formatter.formattingContext = .middleOfSentence

		let comparator = date.isToday ? yesterday : NTSolar(for: Date(), coordinate: self.coordinate, timeZone: timeZone, calendar: calendar)
		let difference = daylightDuration - (comparator?.daylightDuration ?? 0)
		let differenceString = Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2))

		let moreOrLess = difference >= 0 ? NSLocalizedString("more", comment: "More daylight middle of sentence") : NSLocalizedString("less", comment: "Less daylight middle of sentence")

		// Check if the base date formatted as a string contains numbers.
		// If it does, this means it's presented as an absolute date, and should
		// be rendered as "on {date}"; if not, it's presented as a relative date,
		// and should be presented as "{yesterday/today/tomorrow}"
		var baseDateString = formatter.string(from: date)
		if baseDateString.contains(/\d/) {
			baseDateString = NSLocalizedString("on \(baseDateString)", comment: "Sentence fragment for nominal date")
		}

		let comparatorDate = comparator?.date ?? self.date

		return LocalizedStringKey("\(differenceString) \(moreOrLess) daylight \(baseDateString) compared to \(formatter.string(from: comparatorDate))")
	}
}

// MARK: - Events
extension NTSolar {
	var events: Array<Event> {
		[
			Event(label: "Astronomical Sunrise", date: astronomicalSunrise, phase: .astronomical),
			Event(label: "Nautical Sunrise", date: nauticalSunrise, phase: .nautical),
			Event(label: "Civil Sunrise", date: civilSunrise, phase: .civil),
			Event(label: "Sunrise", date: safeSunrise, phase: .sunrise),
			Event(label: "Solar noon", date: culmination, phase: .day),
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

	var nextSolarEvent: Event? {
		let sunriseOrSunsetEvents: [Event] = events.filter { $0.phase == .sunset || $0.phase == .sunrise }
		let todayEvent: Event? = sunriseOrSunsetEvents.first(where: { $0.date > date })
		if let todayEvent {
			return todayEvent
		}
		let tomorrowEvents: [Event] = tomorrow?.events.filter { $0.phase == .sunset || $0.phase == .sunrise } ?? []
		return tomorrowEvents.first(where: { $0.date > date })
	}

	var previousSolarEvent: Event? {
		let sunriseOrSunsetEvents: [Event] = events.filter { $0.phase == .sunset || $0.phase == .sunrise }
		let todayEvent: Event? = sunriseOrSunsetEvents.last(where: { $0.date < date })
		if let todayEvent {
			return todayEvent
		}
		let fallbackSolar: NTSolar = yesterday ?? self
		let fallbackEvents: [Event] = fallbackSolar.events.filter { $0.phase == .sunset || $0.phase == .sunrise }
		return fallbackEvents.last(where: { $0.date < date })
	}
}

// MARK: - View Helpers
extension NTSolar {
	var view: some View {
		SkyGradient(ntSolar: self)
	}
}
