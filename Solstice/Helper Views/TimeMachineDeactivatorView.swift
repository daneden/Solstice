//
//  TimeMachineDeactivatorView.swift
//  Solstice
//
//  Created by Daniel Eden on 16/03/2023.
//

import SwiftUI

struct TimeMachineDeactivatorView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
	#if os(macOS)
	var body: some View {
		label
	}
	#else
	var body: some View {
		DisclosureGroup {
			TimeMachineView()
		} label: {
			label
		}
	}
	#endif
	
	var label: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Time Travel \(timeMachine.isOn ? Text("active") : Text("inactive"))")
					.font(.headline)
				Text(timeMachine.date, style: .date)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
			
			Button {
				withAnimation(.interactiveSpring()) {
					timeMachine.isOn.toggle()
				}
			} label: {
				Text("Reset")
			}
			.buttonStyle(.bordered)
			#if os(iOS)
			.buttonBorderShape(.capsule)
			#endif
		}
	}
}

struct TimeMachineDeactivatorView_Previews: PreviewProvider {
	static var previews: some View {
		TimeMachineDeactivatorView()
			.environmentObject(TimeMachine.preview)
	}
}
