//
//  TimeMachineView.swift
//  Solstice
//
//  Created by Daniel Eden on 18/02/2023.
//

import SwiftUI

struct TimeMachineView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
	@State private var date = Date()
	@State private var referenceDate = Date()
	@State private var showDatePicker = false
	
	#if os(watchOS)
	var body: some View {
		Section {
			Toggle(isOn: timeMachine.isOn) {
				Text("Enable Time Travel")
			}
			
			Group {
				controls
			}.disabled(!timeMachine.enabled)
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
		HStack {
			Button {
				withAnimation(.snappy) { showDatePicker.toggle() }
			} label: {
				Label {
					HStack {
						Group {
							let date = Text(timeMachine.date, style: .date)
							let label = Text("Time Travel")
							
							Text("\(timeMachine.enabled ? date : label)")
								.monospacedDigit()
						}
						
						Image(systemName: "chevron.forward")
							.rotationEffect(Angle(degrees: showDatePicker ? 90 : 0))
							.foregroundStyle(.secondary)
							.imageScale(.small)
					}
					.transition(.blurReplace)
					.contentTransition(.numericText())
				} icon: {
					Image(systemName: "clock.arrow.2.circlepath")
				}
				.accessibilityLabel("Toggle advanced time travel controls")
			}
			.tint(.primary)
			.fontWeight(.medium)
			#if os(visionOS)
			.buttonStyle(.plain)
			#endif
			
			Spacer()
			
			Button("Reset", systemImage: "arrow.circlepath") {
				withAnimation {
					timeMachine.offset.wrappedValue = 0
				}
			}
			.fontWeight(.medium)
			.disabled(!timeMachine.enabled)
		}
		#endif
		
		#if !os(watchOS)
		Slider(value: timeMachine.offset,
					 in: -182...182,
					 step: 7,
					 minimumValueLabel: Text("-6mo").font(.footnote).monospaced(),
					 maximumValueLabel: Text("+6mo").font(.footnote).monospaced()) {
			Text("\(Int(abs(timeMachine.offset.wrappedValue))) days in the \(timeMachine.offset.wrappedValue > 0 ? Text("future") : Text("past"))")
		}
						#if os(iOS)
					 .tint(Color(UIColor.systemFill))
						#endif
					 .foregroundStyle(.secondary)
					 .labelsHidden()
		#if !os(visionOS)
					 .sensoryFeedback(trigger: timeMachine.offsetAmount) { oldValue, newValue in
						 if newValue == 0 {
							 return .impact
						 } else {
							 return newValue > oldValue ? .increase : .decrease
						 }
					 }
		#endif
		
		if showDatePicker {
			DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: [.date]) {
				Text("Choose date")
			}
			.transition(.blurReplace.combined(with: .move(edge: .bottom)))
		}
		#else
		Stepper(
			value: timeMachine.offset,
			in: -365...365,
			step: 1
		) {
			Text("\(Int(timeMachine.offset.wrappedValue))", comment: "Number of days in the past or future for Time Travel on Apple Watch")
				.font(.largeTitle)
		}
		.foregroundStyle(.secondary)
		
		VStack(alignment: .leading) {
			Text(timeMachine.date, style: .date)
			Text("\(Int(abs(timeMachine.offset.wrappedValue))) days in the \(timeMachine.offset.wrappedValue >= 0 ? Text("future") : Text("past"))")
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
		
		Button {
			withAnimation {
				timeMachine.offset.wrappedValue = 0
			}
		} label: {
			Label("Reset", systemImage: "gobackward")
		}
		.disabled(timeMachine.offset.wrappedValue == 0)
		#endif
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
