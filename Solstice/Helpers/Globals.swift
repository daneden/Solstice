//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

var chartHeight: CGFloat = {
#if os(macOS)
	300
#elseif !os(watchOS)
	400
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

let calendar =  Calendar.autoupdatingCurrent

let localTimeZone = TimeZone.ReferenceType.local
