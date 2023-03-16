//
//  TimeMachineDeactivatorView.swift
//  Solstice
//
//  Created by Daniel Eden on 16/03/2023.
//

import SwiftUI

struct TimeMachineDeactivatorView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
	var body: some View {
		Button {
			withAnimation {
				timeMachine.isOn.toggle()
			}
		} label: {
			HStack {
				VStack(alignment: .leading) {
					Text("Time Machine \(timeMachine.isOn ? "Active" : "Inactive")")
					Text(timeMachine.date, style: .date)
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				Image(systemName: "clock.arrow.2.circlepath")
			}
			.contentShape(Rectangle())
		}
		#if os(macOS)
		.buttonStyle(.plain)
		#else
		.buttonStyle(.borderedProminent)
		#endif
		.listRowBackground(Color.clear)
		.listRowInsets(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
	}
}

struct TimeMachineDeactivatorView_Previews: PreviewProvider {
	static var previews: some View {
		TimeMachineDeactivatorView()
			.environmentObject(TimeMachine.preview)
	}
}
