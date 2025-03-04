//
//  Date++.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Foundation

extension Date {
	var startOfDay: Date {
		calendar.startOfDay(for: self)
	}
	
	var endOfDay: Date {
		calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
	}
	
	var isToday: Bool {
		calendar.isDateInToday(self)
	}
	
	func withTimeZoneAdjustment(for timeZone: TimeZone?) -> Date {
		guard let timeZone else { return self }
		let tzOffset = timeZone.secondsFromGMT(for: self) - localTimeZone.secondsFromGMT(for: self)
		return self.addingTimeInterval(TimeInterval(tzOffset))
	}
}

/// Allows dates to be stored in AppStorage
extension Date: @retroactive RawRepresentable {
	public var rawValue: String {
		self.timeIntervalSinceReferenceDate.description
	}
	
	public init?(rawValue: String) {
		self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
	}
}

extension DateComponents: @retroactive RawRepresentable {
	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
					let string = String(data: data, encoding: .utf8) else {
			return "{}"
		}
		
		return string
	}
	
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
					let decoded = try? JSONDecoder().decode(DateComponents.self, from: data) else {
			return nil
		}
		
		self = decoded
	}
}
