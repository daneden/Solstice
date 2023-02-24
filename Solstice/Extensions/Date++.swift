//
//  Date++.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Foundation

extension Date {
	var startOfDay: Date {
		Calendar.autoupdatingCurrent.startOfDay(for: self)
	}
	
	var endOfDay: Date {
		Calendar.autoupdatingCurrent.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
	}
	
	var isToday: Bool {
		let calendar = Calendar.current
		return calendar.isDateInToday(self)
	}
	
	func withTimeZoneAdjustment(for timeZone: TimeZone?) -> Date {
		guard let timeZone else { return self }
		let dstOffset = timeZone.daylightSavingTimeOffset(for: self)
		let tzOffset = timeZone.secondsFromGMT(for: self) - TimeZone.autoupdatingCurrent.secondsFromGMT(for: self)
		return self.addingTimeInterval(dstOffset + TimeInterval(tzOffset))
	}
}

/// Allows dates to be stored in AppStorage
extension Date: RawRepresentable {
	public var rawValue: String {
		self.timeIntervalSinceReferenceDate.description
	}
	
	public init?(rawValue: String) {
		self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
	}
}
