//
//  AdaptiveStack.swift
//  Solstice
//
//  Created by Daniel Eden on 18/09/2025.
//

import SwiftUI

struct AdaptiveStack<A: View, B: View>: View {
	@ViewBuilder var content: () -> B
	@ViewBuilder var label: () -> A
	
    var body: some View {
			ViewThatFits {
				HStack {
					label()
					
					Spacer()
					
					content()
						.foregroundStyle(.secondary)
				}
				
				VStack(alignment: .leading) {
					label()
					content()
						.foregroundStyle(.secondary)
				}
			}
    }
}

#Preview {
	AdaptiveStack {
		Text("Hello world")
	} label: {
		Label("Label", systemImage: "heart")
	}
}
