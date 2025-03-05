//
//  StackedButtonStyle.swift
//  Solstice
//
//  Created by Daniel Eden on 05/03/2025.
//

import SwiftUI

struct StackedButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.labelStyle(StackedLabelStyle())
	}
}

#Preview {
	Button("Share", systemImage: "square.and.arrow.up") {
		
	}
	.buttonStyle(StackedButtonStyle())
}
