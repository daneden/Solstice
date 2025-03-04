//
//  View+DaylightGradientTimePreferenceKey.swift
//  Solstice
//
//  Created by Daniel Eden on 04/03/2025.
//

import SwiftUI

struct DaylightGradientTimePreferenceKey: PreferenceKey {
	typealias Value = Date
	
	static let defaultValue: Date = Date()
	
	static func reduce(value: inout Date, nextValue: () -> Date) {
		value = nextValue()
	}
}
