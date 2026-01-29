//
//  SunKit++.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//  Migrated from Solar++ to SunKit
//

import SwiftUI
import SunKit
import Charts
import CoreLocation

// MARK: - Solar Event Types
extension Sun {
	struct Event: Hashable, Identifiable {
		var id: Int { hashValue }
		let label: String
		var date: Date
		let phase: Phase

		init(label: String, date: Date, phase: Phase) {
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

	var phases: [Phase: (sunrise: Date, sunset: Date)] {
		[
			.astronomical: (astronomicalDawn, astronomicalDusk),
			.nautical: (nauticalDawn, nauticalDusk),
			.civil: (civilDawn, civilDusk),
			.day: (safeSunrise, safeSunset)
		]
	}
}

// MARK: - Compatibility Properties (Solar naming conventions)
extension Sun {
	/// Maps SunKit's astronomicalDawn to Solar's astronomicalSunrise
	var astronomicalSunrise: Date { astronomicalDawn }

	/// Maps SunKit's astronomicalDusk to Solar's astronomicalSunset
	var astronomicalSunset: Date { astronomicalDusk }

	/// Maps SunKit's nauticalDawn to Solar's nauticalSunrise
	var nauticalSunrise: Date { nauticalDawn }

	/// Maps SunKit's nauticalDusk to Solar's nauticalSunset
	var nauticalSunset: Date { nauticalDusk }

	/// Maps SunKit's civilDawn to Solar's civilSunrise
	var civilSunrise: Date { civilDawn }

	/// Maps SunKit's civilDusk to Solar's civilSunset
	var civilSunset: Date { civilDusk }

	/// The coordinate used for calculations
	var coordinate: CLLocationCoordinate2D {
		location.coordinate
	}

	/// Calendar for date calculations
	var calendar: Calendar {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		return calendar
	}
}

// MARK: - Day Boundaries
extension Sun {
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
		let halfDistance = abs(safeSunrise.timeIntervalSince(safeSunset)) / 2
		return safeSunrise.addingTimeInterval(halfDistance)
	}
}

// MARK: - Safe Sunrise/Sunset
extension Sun {
	var fallbackSunrise: Date {
		// SunKit always returns dates, but for polar edge cases we cascade through twilight
		if isCircumPolar {
			if isAlwaysDay {
				return startOfDay
			} else if isAlwaysNight {
				return startOfDay.addingTimeInterval(.twentyFourHours / 2)
			}
		}
		return sunrise
	}

	var fallbackSunset: Date {
		if isCircumPolar {
			if isAlwaysDay {
				return endOfDay
			} else if isAlwaysNight {
				return startOfDay.addingTimeInterval(.twentyFourHours / 2)
			}
		}
		return sunset
	}

	var safeSunrise: Date {
		if isCircumPolar {
			if isAlwaysNight {
				// Polar night - return midday as a placeholder
				return startOfDay.addingTimeInterval(.twentyFourHours / 2)
			} else if isAlwaysDay {
				// Midnight sun - sunrise is effectively start of day
				return startOfDay
			}
		}
		return sunrise
	}

	var safeSunset: Date {
		if isCircumPolar {
			if isAlwaysNight {
				// Polar night - return midday as a placeholder
				return startOfDay.addingTimeInterval(.twentyFourHours / 2)
			} else if isAlwaysDay {
				// Midnight sun - sunset is effectively end of day
				return endOfDay
			}
		}
		return sunset
	}

	var daylightDuration: TimeInterval {
		if isCircumPolar {
			if isAlwaysDay {
				return .twentyFourHours
			} else if isAlwaysNight {
				return 0
			}
		}
		return sunset.timeIntervalSince(sunrise)
	}
}

// MARK: - Related Days
extension Sun {
	var yesterday: Sun {
		let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(-(.twentyFourHours))
		return Sun(location: location, timeZone: timeZone, date: yesterdayDate)
	}

	var tomorrow: Sun {
		let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(.twentyFourHours)
		return Sun(location: location, timeZone: timeZone, date: tomorrowDate)
	}

	/// Creates a Sun for the previous day, reusing an existing instance if provided
	func getYesterday(cachedYesterday: inout Sun?) -> Sun {
		if let cached = cachedYesterday {
			let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(-(.twentyFourHours))
			var updated = cached
			updated.setDate(yesterdayDate)
			cachedYesterday = updated
			return updated
		}
		let newYesterday = yesterday
		cachedYesterday = newYesterday
		return newYesterday
	}

	/// Creates a Sun for the next day, reusing an existing instance if provided
	func getTomorrow(cachedTomorrow: inout Sun?) -> Sun {
		if let cached = cachedTomorrow {
			let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(.twentyFourHours)
			var updated = cached
			updated.setDate(tomorrowDate)
			cachedTomorrow = updated
			return updated
		}
		let newTomorrow = tomorrow
		cachedTomorrow = newTomorrow
		return newTomorrow
	}
}

// MARK: - Difference Strings
extension Sun {
	var compactDifferenceString: LocalizedStringKey {
		compactDifferenceString(comparator: nil)
	}

	/// Computes the compact difference string, optionally using a pre-computed comparator Sun
	func compactDifferenceString(comparator: Sun?) -> LocalizedStringKey {
		let comp = comparator ?? (date.isToday ? yesterday : Sun(location: location, timeZone: timeZone))
		let difference = daylightDuration - comp.daylightDuration
		let differenceString = Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2))

		let moreOrLess = difference >= 0 ? "+" : "-"

		return LocalizedStringKey("\(moreOrLess)\(differenceString)")
	}

	var differenceString: LocalizedStringKey {
		differenceString(comparator: nil)
	}

	/// Computes the difference string, optionally using a pre-computed comparator Sun
	func differenceString(comparator: Sun?) -> LocalizedStringKey {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = true
		formatter.dateStyle = .medium
		formatter.formattingContext = .middleOfSentence

		let comp = comparator ?? (date.isToday ? yesterday : Sun(location: location, timeZone: timeZone))
		let difference = daylightDuration - comp.daylightDuration
		let differenceString = Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2))

		let moreOrLess = difference >= 0 ? NSLocalizedString("more", comment: "More daylight middle of sentence") : NSLocalizedString("less", comment: "Less daylight middle of sentence")

		var baseDateString = formatter.string(from: date)
		if baseDateString.contains(/\d/) {
			baseDateString = NSLocalizedString("on \(baseDateString)", comment: "Sentence fragment for nominal date")
		}

		let comparatorDate = comp.date

		return LocalizedStringKey("\(differenceString) \(moreOrLess) daylight \(baseDateString) compared to \(formatter.string(from: comparatorDate))")
	}
}

// MARK: - Events
extension Sun {
	var events: Array<Event> {
		[
			Event(label: "Astronomical Sunrise", date: astronomicalDawn, phase: .astronomical),
			Event(label: "Nautical Sunrise", date: nauticalDawn, phase: .nautical),
			Event(label: "Civil Sunrise", date: civilDawn, phase: .civil),
			Event(label: "Sunrise", date: safeSunrise, phase: .sunrise),
			Event(label: "Solar noon", date: solarNoon, phase: .day),
			Event(label: "Sunset", date: safeSunset, phase: .sunset),
			Event(label: "Civil Sunset", date: civilDusk, phase: .civil),
			Event(label: "Nautical Sunset", date: nauticalDusk, phase: .nautical),
			Event(label: "Astronomical Sunset", date: astronomicalDusk, phase: .astronomical),
		]
		.sorted { a, b in
			a.date.compare(b.date) == .orderedAscending
		}
	}

	var nextSolarEvent: Event? {
		nextSolarEvent(cachedTomorrow: nil)
	}

	/// Gets the next solar event, optionally using a pre-computed tomorrow Sun
	func nextSolarEvent(cachedTomorrow: Sun?) -> Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
		?? (cachedTomorrow ?? tomorrow).events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
	}

	var previousSolarEvent: Event? {
		previousSolarEvent(cachedYesterday: nil)
	}

	/// Gets the previous solar event, optionally using a pre-computed yesterday Sun
	func previousSolarEvent(cachedYesterday: Sun?) -> Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.last(where: { $0.date < date })
		?? (cachedYesterday ?? yesterday).events.filter { $0.phase == .sunset || $0.phase == .sunrise }.last(where: { $0.date < date })
	}
}

// MARK: - Convenience Initializer (Solar-style API)
extension Sun {
	/// Creates a Sun instance using Solar-style API
	/// - Parameters:
	///   - date: The date for calculations
	///   - coordinate: The geographic coordinate
	///   - timeZone: The timezone (defaults to current)
	init(for date: Date, coordinate: CLLocationCoordinate2D, timeZone: TimeZone = .current) {
		let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		self.init(location: location, timeZone: timeZone, date: date)
	}

	/// Creates a Sun instance for the current date at a coordinate
	/// - Parameter coordinate: The geographic coordinate
	init(coordinate: CLLocationCoordinate2D, timeZone: TimeZone = .current) {
		self.init(for: Date(), coordinate: coordinate, timeZone: timeZone)
	}
}
