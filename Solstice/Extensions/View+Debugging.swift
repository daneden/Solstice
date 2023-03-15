//
//  View+Debugging.swift
//  Solstice
//
//  Created by Daniel Eden on 15/03/2023.
//

import Foundation
import SwiftUI

extension ShapeStyle where Self == Color {
	static var random: Color {
		Color(
			red: .random(in: 0...1),
			green: .random(in: 0...1),
			blue: .random(in: 0...1)
		)
	}
}

extension View {
	func debugWithRandomColor() -> some View {
		self.background(.random)
	}
}
