//
//  LunarCalculator++.swift
//  Solstice
//
//  Created by Daniel Eden on 11/08/2026.
//
//  The app's presentation layer over `LunarCalculator`. Kept separate so the calculator
//  itself imports nothing but Foundation and CoreLocation, and can be compiled into the
//  widget targets without dragging SwiftUI along.
//

import SwiftUI

extension LunarCalculator.Phase {
	var localizedName: LocalizedStringKey {
		switch self {
		case .new: "New moon"
		case .waxingCrescent: "Waxing crescent"
		case .firstQuarter: "First quarter"
		case .waxingGibbous: "Waxing gibbous"
		case .full: "Full moon"
		case .waningGibbous: "Waning gibbous"
		case .lastQuarter: "Last quarter"
		case .waningCrescent: "Waning crescent"
		}
	}

	/// The SF Symbol for this phase, mirrored for southern-hemisphere observers.
	///
	/// The moon is lit from the same side for everyone, but observers south of the equator
	/// see it the other way up, so the lit limb appears on the opposite side. SF Symbols
	/// ships `.inverse` variants for exactly this. New and full moons are symmetrical and
	/// need no variant.
	func symbolName(latitude: Double) -> String {
		let base: String
		switch self {
		case .new: return "moonphase.new.moon"
		case .full: return "moonphase.full.moon"
		case .waxingCrescent: base = "moonphase.waxing.crescent"
		case .firstQuarter: base = "moonphase.first.quarter"
		case .waxingGibbous: base = "moonphase.waxing.gibbous"
		case .waningGibbous: base = "moonphase.waning.gibbous"
		case .lastQuarter: base = "moonphase.last.quarter"
		case .waningCrescent: base = "moonphase.waning.crescent"
		}

		return latitude < 0 ? "\(base).inverse" : base
	}
}

extension LunarCalculator.Moon {
	/// Illumination as a percentage string, e.g. "68%".
	var formattedIllumination: String {
		illuminatedFraction.formatted(.percent.precision(.fractionLength(0)))
	}
}
