//
//  TimeMachineView.swift
//  Solstice
//
//  Created by Daniel Eden on 18/02/2023.
//

import SwiftUI

struct TimeMachineView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
    var body: some View {
			DisclosureGroup {
				DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: [.date]) {
					Text("Choose Date")
				}
				#if !os(macOS)
				.datePickerStyle(.wheel)
				#endif
				
				Button {
					timeMachine.resetTimeMachine()
				} label: {
					Label("Reset Date", systemImage: "arrow.counterclockwise")
				}
				.disabled(timeMachine.date != timeMachine.targetDate)
			} label: {
				Label {
					Text(timeMachine.date, style: .date)
						.fontWeight(timeMachine.date.isToday ? .regular : .semibold)
						.capsuleAppearance(on: !timeMachine.date.isToday)
				} icon: {
					Image(systemName: "calendar.badge.clock")
				}
			}
    }
}

struct TimeMachineView_Previews: PreviewProvider {
    static var previews: some View {
        TimeMachineView()
    }
}
