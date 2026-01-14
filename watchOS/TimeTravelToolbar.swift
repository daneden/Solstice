//
//  TimeTravelToolbar.swift
//  Solstice watchOS Watch App
//
//  Created by Daniel Eden on 07/09/2025.
//

import SwiftUI
import TimeMachine

struct TimeTravelToolbar: ViewModifier{
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	
	func body(content: Content) -> some View {
		content
			.toolbar {
				ToolbarItemGroup(placement: .bottomBar) {
					HStack {
						Button("Time travel 1 week earlier", systemImage: "backward") {
							withAnimation {
								timeMachine.offset -= 7
							}
						}
						
						if timeMachine.isActive {
							Button {
								withAnimation {
									timeMachine.offset = 0
								}
							} label: {
								Text("Reset")
									.frame(maxWidth: .infinity)
							}
						} else {
							Spacer()
						}
						
						Button("Time travel 1 week later", systemImage: "forward") {
							withAnimation {
								timeMachine.offset += 7
							}
						}
					}
				}
			}
	}
}

extension View {
	func timeTravelToolbar() -> some View {
		modifier(TimeTravelToolbar())
	}
}
