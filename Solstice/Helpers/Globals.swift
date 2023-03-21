//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

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
