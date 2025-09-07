//
//  TimeTravelToolbar.swift
//  Solstice watchOS Watch App
//
//  Created by Daniel Eden on 07/09/2025.
//

import SwiftUI

struct TimeTravelToolbar: ViewModifier{
	@EnvironmentObject var timeMachine: TimeMachine
	
	func body(content: Content) -> some View {
		content
			.toolbar {
				ToolbarItemGroup(placement: .bottomBar) {
					HStack {
						Button("Time travel 1 week earlier", systemImage: "backward") {
							withAnimation {
								timeMachine.offset.wrappedValue -= 7
							}
						}
						
						Spacer(minLength: 0)
						
						if timeMachine.enabled {
							Button("Reset") {
								withAnimation {
									timeMachine.offset.wrappedValue = 0
								}
							}
						}
						
						Spacer(minLength: 0)
						
						Button("Time travel 1 week later", systemImage: "forward") {
							withAnimation {
								timeMachine.offset.wrappedValue += 7
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
