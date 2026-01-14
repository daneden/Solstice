//
//  Color+Mix.swift
//  Solstice
//
//  Created by Daniel Eden on 24/06/2024.
//

import SwiftUI

// MARK: - Platform-specific Color Type
#if canImport(UIKit)
public typealias NativeColor = UIColor
#elseif canImport(AppKit)
public typealias NativeColor = NSColor
#endif

// MARK: - Color Mixing
public extension NativeColor {
	func mix(with target: NativeColor, amount: CGFloat) -> Self {
		var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
		var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

		getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
		target.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

		return Self(
			red: r1 * (1.0 - amount) + r2 * amount,
			green: g1 * (1.0 - amount) + g2 * amount,
			blue: b1 * (1.0 - amount) + b2 * amount,
			alpha: a1
		)
	}
}

public extension Color {
	func mix(with target: Color, by amount: CGFloat) -> Color {
		Color(NativeColor(self).mix(with: NativeColor(target), amount: amount))
	}
}

// MARK: - Hex Conversion
extension Color {
	func toHex() -> String? {
		let uic = NativeColor(self)
		guard let components = uic.cgColor.components, components.count >= 3 else {
			return nil
		}
		let r = Float(components[0])
		let g = Float(components[1])
		let b = Float(components[2])
		var a = Float(1.0)

		if components.count >= 4 {
			a = Float(components[3])
		}

		if a != Float(1.0) {
			return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
		} else {
			return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
		}
	}
}
