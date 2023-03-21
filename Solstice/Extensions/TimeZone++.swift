//
//  TimeZone++.swift
//  Solstice
//
//  Created by Daniel Eden on 05/03/2023.
//

import Foundation

extension TimeZone {
	func differenceFromLocalTime(for date: Date) -> TimeInterval {
		let currentOffset = TimeZone.autoupdatingCurrent.secondsFromGMT(for: date) * -1
		return TimeInterval(self.secondsFromGMT(for: date) + currentOffset)
	}
	
	func differenceStringFromLocalTime(for date: Date) -> String {
		let difference = differenceFromLocalTime(for: date)
		let prefix = difference >= 0 ? "+" : ""
		return "\(prefix)\(difference.abbreviatedHourString)"
	}
}
