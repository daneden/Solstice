//
//  View+CapsuleAppearance.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import Foundation
import SwiftUI

enum CapsuleStyle {
	case normal, prominent
}

struct CapsuleModifier: ViewModifier {
	var appearAsCapsule: Bool = true
	var capsuleStyle: CapsuleStyle = .normal
	
	var backgroundColor: Color {
		switch capsuleStyle {
		case .normal:
			return .accentColor.opacity(0.1)
		case .prominent:
			return .accentColor
		}
	}
	
	var foregroundColor: Color {
		switch capsuleStyle {
		case .normal:
			return .accentColor
		case .prominent:
			return .white
		}
	}
	
	func body(content: Content) -> some View {
		content
			.padding(4)
			.padding(.horizontal, 4)
			.background(appearAsCapsule ? backgroundColor : .clear)
			.foregroundStyle(appearAsCapsule ? foregroundColor : .primary)
			.cornerRadius(6)
			.padding(-4)
			.padding(.horizontal, -4)
	}
}

extension View {
	func capsuleAppearance(on: Bool, style: CapsuleStyle = .normal) -> some View {
		modifier(CapsuleModifier(appearAsCapsule: on, capsuleStyle: style))
	}
}
