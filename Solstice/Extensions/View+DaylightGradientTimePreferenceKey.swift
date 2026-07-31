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

extension View {
	/// Lays a sun-tracking `SkyGradient` behind a chart that publishes
	/// `SkyChartGeometryPreferenceKey` (a `DaylightChart` with `tracksSkyGeometry: true`).
	///
	/// Stateless by design: the published geometry resolves into the background within the same
	/// render pass, so the glow never trails the sun marker by a frame — and the whole assembly
	/// works under `ImageRenderer`, where a preference → state → re-render loop would never run
	/// (the share card renders in a detached tree that gets exactly one pass).
	func skyChartBackground(solar: NTSolar?) -> some View {
		backgroundPreferenceValue(SkyChartGeometryPreferenceKey.self) { geometry in
			GeometryReader { geo in
				let frame = geo.frame(in: .named(SkyGradient.coordinateSpaceName))
				SkyGradient(ntSolar: solar,
				            sunAnchor: normalizedAnchor(geometry?.sunPoint, in: frame),
				            horizonFraction: normalizedHorizon(geometry?.horizonY, in: frame))
			}
		}
		.coordinateSpace(.named(SkyGradient.coordinateSpaceName))
	}
}

/// The chart reports positions in the shared coordinate space; the gradient wants fractions of
/// its own bounds.
private func normalizedAnchor(_ point: CGPoint?, in frame: CGRect) -> UnitPoint? {
	guard let point, frame.width > 0, frame.height > 0 else { return nil }
	return UnitPoint(x: (point.x - frame.minX) / frame.width,
	                 y: (point.y - frame.minY) / frame.height)
}

private func normalizedHorizon(_ y: CGFloat?, in frame: CGRect) -> Double? {
	guard let y, frame.height > 0 else { return nil }
	return (y - frame.minY) / frame.height
}
