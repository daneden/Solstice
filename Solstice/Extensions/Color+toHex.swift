//
//  Color+toHex.swift
//  Solstice
//
//  Created by Daniel Eden on 04/03/2025.
//

import SwiftUI

extension Color {
	func toHex() -> String? {
		let uic = UIColor(self)
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
			return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
		} else {
			return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
		}
	}
}
