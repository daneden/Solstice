//
//  TimeMachineView.swift
//  Solstice
//
//  Created by Daniel Eden on 18/02/2023.
//

import SwiftUI

#if canImport(WatchDatePicker)
import WatchDatePicker
#endif

struct TimeMachineView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
	@State private var date = Date()
	@State private var referenceDate = Date()
	
	
#if os(watchOS) || os(macOS)
	var body: some View {
		Section {
			Toggle(isOn: $timeMachine.isOn.animation(.interactiveSpring())) {
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
#if !os(watchOS)
		DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: .date) {
			Text("\(Image(systemName: "clock.arrow.2.circlepath")) Time Travel")
		}
#elseif canImport(WatchDatePicker)
		WatchDatePicker.DatePicker("Select Date", selection: $timeMachine.targetDate, mode: .date)
#endif
		
		#if os(iOS) || os(macOS)
		Slider(value: timeMachine.offset,
					 in: -182...182,
					 step: 1,
					 minimumValueLabel: Text("Past").font(.caption),
					 maximumValueLabel: Text("Future").font(.caption)) {
			Text("\(Int(abs(timeMachine.offset.wrappedValue))) days in the \(timeMachine.offset.wrappedValue > 0 ? "future" : "past")")
		}
						#if os(iOS)
					 .tint(Color(UIColor.systemFill))
						#endif
					 .foregroundStyle(.secondary)
		#endif
	}
	
	var dateRange: ClosedRange<Date> {
		let begin = calendar.date(byAdding: .month, value: -6, to: timeMachine.referenceDate) ?? timeMachine.referenceDate
		let end = calendar.date(byAdding: .month, value: 6, to: timeMachine.referenceDate) ?? timeMachine.referenceDate
		return begin...end
	}
}

struct TimeMachineView_Previews: PreviewProvider {
	static var previews: some View {
		Form {
			TimeMachineView()
		}
		.environmentObject(TimeMachine.preview)
	}
}
