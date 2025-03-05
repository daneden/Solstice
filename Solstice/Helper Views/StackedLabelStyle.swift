//
//  StackedLabelStyle.swift
//  Solstice
//
//  Created by Daniel Eden on 05/03/2025.
//

import SwiftUI

struct StackedLabelStyle: LabelStyle {
	@ScaledMetric var size = 56.0
	func makeBody(configuration: Configuration) -> some View {
		VStack {
			configuration.icon
				.frame(width: size, height: size)
				.background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12, style: .continuous))
				.foregroundStyle(.tint)
			configuration.title
		}
		.font(.body)
	}
}

#Preview {
	Label("Share", systemImage: "square.and.arrow.up")
		.labelStyle(StackedLabelStyle())
}
