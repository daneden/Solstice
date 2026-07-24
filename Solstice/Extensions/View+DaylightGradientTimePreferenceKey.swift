//
//  View+DaylightGradientTimePreferenceKey.swift
//  Solstice
//
//  Created by Daniel Eden on 04/03/2025.
//

import SwiftUI

struct DaylightGradientTimePreferenceKey: PreferenceKey {
	typealias Value = Date

	static let defaultValue: Date = .init()

	static func reduce(value: inout Date, nextValue: () -> Date) {
		value = nextValue()
	}
}

/// The sun marker's position, in the `skyGradient` named coordinate space, published up from a chart
/// so the `SkyGradient` background can anchor its glow to it. See `SkyGradient.coordinateSpaceName`.
struct SkySunAnchorPreferenceKey: PreferenceKey {
	typealias Value = CGPoint?

	static let defaultValue: CGPoint? = nil

	static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
		value = nextValue() ?? value
	}
}
