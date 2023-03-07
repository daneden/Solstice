//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

var timeIntervalFormatter: DateComponentsFormatter {
	let formatter = DateComponentsFormatter()
	formatter.maximumUnitCount = 2
	formatter.unitsStyle = .short
	return formatter
}

var relativeDateFormatter: RelativeDateTimeFormatter {
	let formatter = RelativeDateTimeFormatter()
	formatter.dateTimeStyle = .named
	formatter.formattingContext = .standalone
	return formatter
}
