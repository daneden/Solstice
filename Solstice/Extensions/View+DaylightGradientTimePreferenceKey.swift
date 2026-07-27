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

/// Geometry a chart publishes so its `SkyGradient` background can align with it: the sun marker's
/// position (glow anchor) and the horizon line's y (sky/ground boundary), both in the `skyGradient`
/// named coordinate space. See `SkyGradient.coordinateSpaceName`.
struct SkyChartGeometry: Equatable {
	var sunPoint: CGPoint?
	var horizonY: CGFloat?
}

struct SkyChartGeometryPreferenceKey: PreferenceKey {
	static let defaultValue: SkyChartGeometry? = nil

	static func reduce(value: inout SkyChartGeometry?, nextValue: () -> SkyChartGeometry?) {
		value = nextValue() ?? value
	}
}
