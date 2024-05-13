//
//  ToggledContent.swift
//  Solstice
//
//  Created by Daniel Eden on 15/09/2023.
//

import SwiftUI

struct ContentToggle<Content: View>: View {
	@State var showToggledContent = false
	@ViewBuilder var content: (Bool) -> Content
	
	var body: some View {
		HStack {
			content(showToggledContent)
				.transition(.blurReplace(.upUp))
		}
			.animation(.default, value: showToggledContent)
			.onTapGesture {
				showToggledContent.toggle()
			}
		#if os(visionOS)
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.contentShape(.hoverEffect, .rect(cornerRadius: 12, style: .continuous))
			.hoverEffect()
			.padding(.horizontal, -8)
			.padding(.vertical, -4)
		#endif
	}
}

#Preview {
	ContentToggle(showToggledContent: true) { showContent in
		if showContent {
			Text(verbatim: "Content #1")
				.font(.headline)
		} else {
			Text(verbatim: "Content #2")
				.font(.largeTitle)
		}
	}
}
