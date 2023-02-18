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
}
