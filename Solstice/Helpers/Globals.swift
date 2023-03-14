//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

var timeIntervalFormatter: DateComponentsFormatter = {
	let formatter = DateComponentsFormatter()
	formatter.maximumUnitCount = 2
	formatter.unitsStyle = .short
	return formatter
}()

var relativeDateFormatter: RelativeDateTimeFormatter = {
	let formatter = RelativeDateTimeFormatter()
	formatter.dateTimeStyle = .named
	formatter.formattingContext = .beginningOfSentence
	return formatter
}()

var chartHeight: CGFloat = {
#if !os(watchOS)
	300
#else
	200
#endif
}()

var chartMarkSize: Double = {
#if os(watchOS)
	4
#else
	8
#endif
}()

let calendar = Calendar.autoupdatingCurrent
