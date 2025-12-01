//
//  TimeMachine++.swift
//  Solstice
//
//  Created by Daniel Eden on 19/09/2025.
//

import Foundation
import TimeMachine

extension TimeMachine {
	static var solsticeTimeMachine = TimeMachine(incrementUnit: .day, incrementRange: -182...182)
	
	func dateLabel(context: DateFormatter.Context = .standalone) -> String {
		let formatter = DateFormatter()
		formatter.formattingContext = context
		formatter.doesRelativeDateFormatting = true
		formatter.timeStyle = .none
		formatter.dateStyle = .medium
		
		return formatter.string(from: date)
	}
}
