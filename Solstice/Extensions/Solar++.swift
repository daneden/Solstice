//
//  Solar+safety.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import SwiftUI
import Solar

extension Solar {
	var fallbackSunrise: Date? {
		sunrise ?? civilSunrise ?? nauticalSunrise ?? astronomicalSunrise
	}
	
	var fallbackSunset: Date? {
		sunset ?? civilSunset ?? nauticalSunset ?? astronomicalSunset
	}
	
	var safeSunrise: Date {
		sunrise ?? startOfDay
	}
	
	var safeSunset: Date {
		if let sunset {
			return sunset
		}
		
		guard let fallbackSunset,
					let fallbackSunrise else {
			return endOfDay
		}
		
		if fallbackSunrise.distance(to: fallbackSunset) > (60 * 60 * 7) {
			return endOfDay
		} else {
			return startOfDay.addingTimeInterval(0.1)
		}
	}
	
	var daylightDuration: TimeInterval {
		(fallbackSunrise ?? safeSunrise).distance(to: (fallbackSunset ?? safeSunset))
	}
	
	var peak: Date {
		(fallbackSunrise ?? safeSunrise).addingTimeInterval(abs(daylightDuration) / 2)
	}
	
	var yesterday: Solar {
		let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(60 * 60 * 24 - 1)
		return Solar(for: yesterdayDate, coordinate: coordinate)!
	}
	
	var compactDifferenceString: LocalizedStringKey {
		let comparator = date.isToday ? yesterday : Solar(coordinate: self.coordinate)!
		let difference = daylightDuration - comparator.daylightDuration
		let differenceString = Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2))
		
		let moreOrLess = difference >= 0 ? "+" : "-"
		
		return LocalizedStringKey("\(moreOrLess)\(differenceString)")
	}
	
	var differenceString: LocalizedStringKey {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = true
		formatter.dateStyle = .medium
		formatter.formattingContext = .middleOfSentence
		
		let comparator = date.isToday ? yesterday : Solar(coordinate: self.coordinate)!
		let difference = daylightDuration - comparator.daylightDuration
		let differenceString = Duration.seconds(abs(difference)).formatted(.units(maximumUnitCount: 2))
		
		let moreOrLess = difference >= 0 ? NSLocalizedString("more", comment: "More daylight middle of sentence") : NSLocalizedString("less", comment: "Less daylight middle of sentence")
		
		// Check if the base date formatted as a string contains numbers.
		// If it does, this means it's presented as an absolute date, and should
		// be rendered as “on {date}”; if not, it’s presented as a relative date,
		// and should be presented as “{yesterday/today/tomorrow}”
		var baseDateString = formatter.string(from: date)
		if baseDateString.contains(/\d/) {
			baseDateString = NSLocalizedString("on \(baseDateString)", comment: "Sentence fragment for nominal date")
		}
		
		let comparatorDate = comparator.date
		
		return LocalizedStringKey("\(differenceString) \(moreOrLess) daylight \(baseDateString) compared to \(formatter.string(from: comparatorDate))")
	}
	
	var nextSolarEvent: Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
		?? tomorrow?.events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
	}
	
	var previousSolarEvent: Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.last(where: { $0.date < date })
		?? yesterday.events.filter { $0.phase == .sunset || $0.phase == .sunrise }.last(where: { $0.date < date })
	}
	
	var tomorrow: Solar? {
		guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else {
			return nil
		}
		
		return Solar(for: tomorrow, coordinate: coordinate)
	}
}
