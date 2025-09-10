//
//  AsyncButton.swift
//  Solstice
//
//  Created by Daniel Eden on 14/08/2025.
//

import SwiftUI

struct AsyncButton<Label: View>: View {
	let action: () async -> Void
	let label: Label
	
	@State var isRunning = false
	
	init(
		action: @escaping () async -> Void,
		@ViewBuilder label: () -> Label
	) {
		self.action = action
		self.label = label()
	}
	
	var body: some View {
		Button {
			isRunning = true
			Task {
				await action()
				isRunning = false
			}
		}	label: {
			label
				.if(isRunning) { content in
					content
						.opacity(0)
						.overlay(ProgressView())
				}
		}
		.disabled(isRunning)
	}
}
