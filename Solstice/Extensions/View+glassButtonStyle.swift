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
				if #available(iOS 26, macOS 26, watchOS 26, *) {
					#if !os(visionOS)
					content.buttonStyle(.glassProminent)
					#else
					content.buttonStyle(.borderedProminent)
					#endif
				} else {
					content.buttonStyle(.borderedProminent)
				}
			}
		case .regular:
			self.modify { content in
				if #available(iOS 26, macOS 26, watchOS 26, *) {
					#if !os(visionOS)
					content.buttonStyle(.glass)
					#else
					content
						.buttonStyle(.bordered)
						.backgroundStyle(.regularMaterial)
					#endif
				} else {
					content
						.buttonStyle(MaterialButtonStyle())
						.backgroundStyle(.regularMaterial)
				}
			}
		}
	}
}

struct MaterialButtonStyle: ButtonStyle {
	@Environment(\.controlSize) private var controlSize

	var paddingAmount: Double {
		switch controlSize {
		case .mini:
			return 4
		case .small:
			return 6
		case .regular:
			return 12
		case .large:
			return 16
		case .extraLarge:
			return 20
		@unknown default:
			return 16
		}
	}
	
	var font: Font {
		switch controlSize {
		case .mini:
			return .caption
		case .small:
			return .subheadline
		case .regular:
			return .body
		case .large:
			return .title3
		case .extraLarge:
			return .title2
		@unknown default:
			return .body
		}
	}
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(font)
			.padding(paddingAmount)
			.padding(.horizontal, paddingAmount / 2)
			.background(.regularMaterial, in: .buttonBorder)
	}
}

#Preview {
	Button("Prominent", action: {}).glassButtonStyle(.prominent)
	Button("Regular", action: {}).glassButtonStyle(.regular)
}
