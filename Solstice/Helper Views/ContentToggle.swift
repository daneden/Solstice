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
				.modify { content in
					if #available(iOS 17, macOS 14, watchOS 10, *) {
						content.transition(.blurReplace)
					} else {
						content
					}
				}
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
			Text("Content #2")
				.font(.largeTitle)
		}
	}
}
