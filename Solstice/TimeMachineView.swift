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
				#if !os(tvOS) && !os(watchOS)
				DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: [.date]) {
					Text("\(Image(systemName: "clock.arrow.2.circlepath")) Time Travel")
				}
				#endif
				
				#if os(iOS)
				Slider(value: timeMachine.offset.animation(),
							 in: -182...182,
							 step: 1,
							 minimumValueLabel: Text("Past").font(.caption),
							 maximumValueLabel: Text("Future").font(.caption)) {
					Text("\(Int(timeMachine.offset.wrappedValue)) days in the \(timeMachine.offset.wrappedValue > 0 ? "future" : "past")")
				}
				.tint(Color(UIColor.systemFill))
				.foregroundStyle(.secondary)
				#elseif os(watchOS)
				Stepper(value: timeMachine.offset, in: -182...182, format: .number) {
					VStack {
						Text("Days from now")
						Text(timeMachine.date, style: .date)
							.foregroundStyle(.secondary)
							.font(.footnote)
					}
				}
				#endif
			}
    }
}

struct TimeMachineView_Previews: PreviewProvider {
	static var previews: some View {
		TimeMachineView()
			.environmentObject(TimeMachine())
	}
}
