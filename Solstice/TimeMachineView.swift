//
//  TimeMachineView.swift
//  Solstice
//
//  Created by Daniel Eden on 18/02/2023.
//

import SwiftUI

struct TimeMachineView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
#if os(watchOS) || os(macOS)
	var body: some View {
		Section {
			Toggle(isOn: $timeMachine.isOn.animation()) {
				Text("Enable Time Travel")
			}
			
			Group {
				controls
			}.disabled(!timeMachine.isOn)
		}
	}
#else
	var body: some View {
		controls
	}
#endif
	
	@ViewBuilder
	var controls: some View {
#if !os(tvOS) && !os(watchOS)
		DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: [.date]) {
			Text("\(Image(systemName: "clock.arrow.2.circlepath")) Time Travel")
		}
#endif
		
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
		
		#if os(watchOS)
		Stepper(
			value: $timeMachine.targetDate,
			in: dateRange,
			step: TimeInterval(60 * 60 * 24)
		) {
			Text(timeMachine.offset.wrappedValue, format: .number)
		}
		#endif
	}
	
	var dateRange: ClosedRange<Date> {
		let begin = Calendar.autoupdatingCurrent.date(byAdding: .month, value: -6, to: timeMachine.referenceDate) ?? timeMachine.referenceDate
		let end = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: timeMachine.referenceDate) ?? timeMachine.referenceDate
		return begin...end
	}
}

struct TimeMachineView_Previews: PreviewProvider {
	static var previews: some View {
		TimeMachineView()
			.environmentObject(TimeMachine())
	}
}
