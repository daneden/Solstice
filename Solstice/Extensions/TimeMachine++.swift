//
//  TimeMachine++.swift
//  Solstice
//
//  Created by Daniel Eden on 19/09/2025.
//

import Foundation
import TimeMachine

extension TimeMachine {
	static var solsticeTimeMachine = TimeMachine(incrementUnit: .day, incrementRange: -182 ... 182)

	func dateLabel(context: DateFormatter.Context = .standalone) -> String {
		let formatter = DateFormatter()
		formatter.formattingContext = context
		formatter.doesRelativeDateFormatting = true
		formatter.timeStyle = .none
		formatter.dateStyle = .medium

		// Anchor relative wording to the TimeMachine's reference date (== the wall
		// clock in normal use) so a pinned capture clock still reads "today".
		let dateString = formatter.string(from: date, relativeTo: referenceDate, calendar: .current)

		// Mid-sentence, an absolute date reads better with a preposition ("on 14 Oct 2026");
		// relative dates ("today"/"yesterday") must not be wrapped. Reuses the localizable
		// "on %@" fragment, mirroring NTSolar.differenceString.
		if context == .middleOfSentence, dateString.contains(/\d/) {
			return String(format: NSLocalizedString("on %@", comment: "Sentence fragment placing a daylight comparison on an absolute date, e.g. 'on 13 Oct 2026'"), dateString)
		}

		return dateString
	}
}
