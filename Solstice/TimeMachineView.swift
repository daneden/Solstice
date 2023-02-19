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
			if timeMachine.isOn {
				DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: [.date]) {
					Text("\(Image(systemName: "clock.arrow.2.circlepath")) Time Travel")
				}
				
				#if os(iOS)
				Slider(value: timeMachine.offset,
							 in: -182...182,
							 step: 1,
							 minimumValueLabel: Text("Past").font(.caption),
							 maximumValueLabel: Text("Future").font(.caption)) {
					Text("\(Int(timeMachine.offset.wrappedValue)) days in the \(timeMachine.offset.wrappedValue > 0 ? "future" : "past")")
				}
				.tint(Color(UIColor.systemFill))
				.foregroundStyle(.secondary)
				#endif
			}
    }
}

struct TimeMachineView_Previews: PreviewProvider {
    static var previews: some View {
        TimeMachineView()
    }
}
