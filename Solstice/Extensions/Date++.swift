//
//  Date++.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Foundation

extension Date {
	func startOfDay(in timeZone: TimeZone) -> Date {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		
		return calendar.startOfDay(for: self)
	}
	
	var startOfDay: Date {
		calendar.startOfDay(for: self)
	}
	
	var endOfDay: Date {
		calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
	}
	
	var isToday: Bool {
		calendar.isDateInToday(self)
	}

	var nextSolsticeMonth: Int {
		calendar.dateComponents([.month], from: nextSolstice).month ?? 6
	}

	func nextSolsticeIncreasesLight(at latitude: Double) -> Bool {
		switch nextSolsticeMonth {
		case 6:
			return latitude > 0
		case 12:
			return latitude < 0
		default:
			return true
		}
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
