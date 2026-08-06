//
//  Calendar++.swift
//  Solstice
//
//  Created by Daniel Eden on 06/08/2026.
//

import Foundation

extension Calendar {
	/// A calendar whose year spans one seasonal cycle.
	///
	/// Most calendars a user can choose already track the sun, and their own months are the
	/// better frame for a chart of daylight: the Persian year starts at the March equinox,
	/// and the Buddhist year is the Gregorian year renumbered. The Islamic calendar is purely
	/// lunar — its 355-day year precesses through the seasons, so a year of it is not a
	/// season at all — and only that case needs substituting.
	var seasonalEquivalent: Calendar {
		switch identifier {
		case .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura:
			var gregorian = Calendar(identifier: .gregorian)
			gregorian.locale = locale
			gregorian.timeZone = timeZone
			return gregorian
		default:
			return self
		}
	}

	/// One sample date per month of the year containing `date`, at midday on the 21st.
	///
	/// The 21st puts the June and December samples on the solstices. A lunisolar leap year
	/// has thirteen months and so yields thirteen dates.
	func monthlySampleDates(inYearContaining date: Date) -> [Date] {
		guard let year = dateInterval(of: .year, for: date) else {
			return []
		}

		var lastDate = self.date(bySetting: .day, value: 21, of: year.start) ?? year.start
		lastDate = self.date(bySetting: .hour, value: 12, of: lastDate) ?? lastDate
		var dates: [Date] = []

		while lastDate < year.end {
			dates.append(lastDate)
			lastDate = self.date(byAdding: .month, value: 1, to: lastDate) ?? lastDate.addingTimeInterval(60 * 60 * 24 * 7 * 4)
		}

		return dates
	}
}
