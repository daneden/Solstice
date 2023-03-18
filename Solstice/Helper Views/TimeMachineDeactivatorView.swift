//
//  TimeMachineDeactivatorView.swift
//  Solstice
//
//  Created by Daniel Eden on 16/03/2023.
//

import SwiftUI

struct TimeMachineDeactivatorView: View {
	@ObservedObject var timeMachine =  TimeMachine.shared
	
	var body: some View {
		Button {
			withAnimation {
				timeMachine.isOn.toggle()
			}
		} label: {
			VStack {
				Label("Time Machine \(timeMachine.isOn ? "Active" : "Inactive")", systemImage: "clock.arrow.2.circlepath")
					.labelStyle(.titleAndIcon)
				Text(timeMachine.date, style: .date)
					.foregroundStyle(.secondary)
			}
			.font(.footnote)
			.contentShape(Rectangle())
		}
		#if os(macOS)
		.buttonStyle(.plain)
		#else
		.buttonStyle(.borderless)
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
