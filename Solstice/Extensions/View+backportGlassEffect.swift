//
//  BackportGlassEffectViewModifier.swift
//  Solstice
//
//  Created by Dan Eden on 16/10/2025.
//

import SwiftUI

struct BackportGlassEffectViewModifier<S: Shape>: ViewModifier {
	#if WIDGET_EXTENSION
	@Environment(\.widgetRenderingMode) private var widgetRenderingMode
	#endif
	
	var shape: S
	
	func body(content: Content) -> some View {
		let fallback = content.background(.regularMaterial, in: shape).shadow(color: .black.opacity(0.1), radius: 8, y: 4)
		
		#if WIDGET_EXTENSION
		content
			.modify { content in
				if widgetRenderingMode == .fullColor {
					fallback
				} else {
					content.background(.background, in: shape)
				}
			}
		#elseif os(visionOS)
		fallback
		#else
		if #available(iOS 26, macOS 26, watchOS 26, *) {
			content.glassEffect(in: shape)
		} else {
			fallback
		}
		#endif
	}
}

extension View {
	func backportGlassEffect<S: Shape>(in shape: S) -> some View {
		modifier(BackportGlassEffectViewModifier(shape: shape))
	}
}
