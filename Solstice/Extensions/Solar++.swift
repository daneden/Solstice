//
//  Solar+safety.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import Foundation
import Solar

extension Solar {
	var safeSunrise: Date {
		return sunrise ?? civilSunrise ?? nauticalSunrise ?? astronomicalSunrise ?? startOfDay
	}
	
	var safeSunset: Date {
		return sunset ?? civilSunset ?? nauticalSunset ?? astronomicalSunset ?? endOfDay
	}
	
	var daylightDuration: TimeInterval {
		safeSunrise.distance(to: safeSunset)
	}
	
	var peak: Date {
		safeSunrise.addingTimeInterval(abs(daylightDuration) / 2)
	}
	
	var yesterday: Solar {
		let yesterdayDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(60 * 60 * 24 - 1)
		return Solar(for: yesterdayDate, coordinate: coordinate)!
	}
	
	var differenceString: String {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = true
		formatter.dateStyle = .medium
		formatter.formattingContext = .middleOfSentence
		
		let comparator = date.isToday ? yesterday : Solar(coordinate: self.coordinate)!
		var string = (daylightDuration - comparator.daylightDuration).localizedString
		
		if daylightDuration - comparator.daylightDuration >= 0 {
			string += " more"
		} else {
			string += " less"
		}
		
		// Check if the base date formatted as a string contains numbers.
		// If it does, this means it's presented as an absolute date, and should
		// be rendered as “on {date}”; if not, it’s presented as a relative date,
		// and should be presented as “{yesterday/today/tomorrow}”
		let baseDateString = formatter.string(from: date)
		let decimalCharacters = CharacterSet.decimalDigits
		let decimalRange = baseDateString.rangeOfCharacter(from: decimalCharacters)
		
		let comparatorDate = comparator.date
		let comparatorDateString = formatter.string(from: comparatorDate)
		
		string += " daylight \(decimalRange == nil ? "" : "on ")\(baseDateString) compared to \(comparatorDateString)."
		
		return string
	}
	
	var nextSolarEvent: Event? {
		events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
		?? tomorrow?.events.filter { $0.phase == .sunset || $0.phase == .sunrise }.first(where: { $0.date > date })
	}
	
	var tomorrow: Solar? {
		guard let tomorrow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: date) else {
			return nil
		}
		
		return Solar(for: tomorrow, coordinate: coordinate)
	}
}
