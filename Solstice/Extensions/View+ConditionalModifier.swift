//
//  View+ConditionalModifier.swift
//  Solstice
//
//  Created by Daniel Eden on 11/03/2023.
//

import SwiftUI

extension View {
	/// Applies the given transform if the given condition evaluates to `true`.
	/// - Parameters:
	///   - condition: The condition to evaluate.
	///   - transform: The transform to apply to the source `View`.
	/// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
	@ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}

extension View {
	/// Applies a given transformation inline. Useful for e.g. `#available` attribute-based content changes
	/// - Parameters:
	///   - transform: The transform to apply to the source `View`
	/// - Returns: The modified `View`
	func modify<Content: View>(@ViewBuilder transform: (Self) -> Content) -> some View {
		transform(self)
	}
}
