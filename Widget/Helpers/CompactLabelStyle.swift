//
//  CompactLabelStyle.swift
//  Solstice
//
//  Created by Daniel Eden on 20/09/2023.
//

import SwiftUI

struct CompactLabelStyle: LabelStyle {
	var spacing: CGFloat = 2
	var reverseOrder = false
	func makeBody(configuration: Configuration) -> some View {
		HStack(alignment: .firstTextBaseline, spacing: spacing) {
			switch reverseOrder {
			case true:
				configuration.title
				configuration.icon
			case false:
				configuration.icon
				configuration.title
			}
		}
	}
}

#Preview {
	Label {
		Text(verbatim: "Test Label")
	} icon: {
		Image(systemName: "sparkles")
	}
		.labelStyle(CompactLabelStyle())
}
