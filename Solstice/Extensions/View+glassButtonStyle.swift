//
//  View+glassButtonStyle.swift
//  Solstice
//
//  Created by Daniel Eden on 14/08/2025.
//

import SwiftUI
import Suite

internal enum BackportGlassButtonStyle {
	case regular, prominent
}

extension View {
	@ViewBuilder
	func glassButtonStyle(_ style: BackportGlassButtonStyle = .regular) -> some View {
		switch style {
		case .prominent:
			self.modify { content in
				if #available(iOS 26, macOS 26, visionOS 26, watchOS 26, *) {
					content.buttonStyle(.glassProminent)
				} else {
					content.buttonStyle(.borderedProminent)
				}
			}
		case .regular:
			self.modify { content in
				if #available(iOS 26, macOS 26, visionOS 26, watchOS 26, *) {
					content.buttonStyle(.glass)
				} else {
					content.buttonStyle(.bordered)
				}
			}
		}
	}
}

#Preview {
	Button("Prominent", action: {}).glassButtonStyle(.prominent)
	Button("Regular", action: {}).glassButtonStyle(.regular)
}
