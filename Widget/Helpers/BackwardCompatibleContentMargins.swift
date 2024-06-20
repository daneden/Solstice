//
//  BackwardCompatibleContentMargins.swift
//  Solstice
//
//  Created by Daniel Eden on 20/06/2024.
//

import SwiftUI

struct BackwardCompatibleContentMargins: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOSApplicationExtension 17, watchOSApplicationExtension 10, macOSApplicationExtension 14, *) {
			content
		} else {
			content.padding()
		}
	}
}

extension View {
	func backwardCompatibleContentMargins() -> some View {
		self.modifier(BackwardCompatibleContentMargins())
	}
}
