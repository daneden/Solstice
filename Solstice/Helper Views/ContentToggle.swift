//
//  ContentToggle.swift
//  Solstice
//
//  Created by Daniel Eden on 15/09/2023.
//

import Suite
import SwiftUI

struct ContentToggle<Content: View>: View {
	@State private var showToggledContent: Bool
	let content: (Bool) -> Content

	init(showToggledContent: Bool = false, @ViewBuilder content: @escaping (Bool) -> Content) {
		_showToggledContent = State(initialValue: showToggledContent)
		self.content = content
	}

	var body: some View {
		HStack {
			content(showToggledContent)
				.transition(.blurReplace)
		}
		.animation(.default, value: showToggledContent)
		.onTapGesture {
			showToggledContent.toggle()
		}
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
