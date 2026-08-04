//
//  TimeTravelOrnamentView.swift
//  Solstice
//
//  Created by Daniel Eden on 04/08/2026.
//

#if os(visionOS)
	import SwiftUI
	import TimeMachine

	struct TimeTravelOrnamentView: View {
		@Environment(\.timeMachine) private var timeMachine

		var body: some View {
			@Bindable var timeMachine = timeMachine

			HStack(spacing: 16) {
				if timeMachine.interfaceState.datePickerVisible {
					Group {
						Button("Time Travel", systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90") {
							withAnimation {
								timeMachine.interfaceState.datePickerVisible = false
							}
						}
						.help("Time Travel slider")

						DatePicker(selection: $timeMachine.date.animation(), displayedComponents: .date) {
							Text("Choose date")
						}
						.labelsHidden()
					}
					.transition(.blurReplace)
				} else {
					Group {
						Slider(value: $timeMachine.offset, in: timeMachine.range, neutralValue: 0) {
							Text("Offset")
						} minimumValueLabel: {
							Text("-6mo")
								.textScale(.secondary)
								.fixedSize()
						} maximumValueLabel: {
							Text("+6mo")
								.textScale(.secondary)
								.fixedSize()
						}
						.labelsHidden()
						.frame(width: 280)

						Button("Choose date", systemImage: "calendar") {
							withAnimation {
								timeMachine.interfaceState.datePickerVisible = true
							}
						}
						.help("Date picker")
					}
					.transition(.blurReplace)
				}

				Divider()

				Button("Reset", systemImage: "arrow.counterclockwise") {
					withAnimation {
						timeMachine.reset()
					}
				}
				.disabled(!timeMachine.isActive)
				.help("Reset to the current date")
			}
			.labelStyle(.iconOnly)
			.buttonStyle(.borderless)
			.buttonBorderShape(.circle)
			.padding(16)
			.glassBackgroundEffect(in: .capsule)
			.animation(.default, value: timeMachine.interfaceState.datePickerVisible)
		}
	}

	#Preview("Slider") {
		TimeTravelOrnamentView()
			.withTimeMachine(.solsticeTimeMachine)
	}

	#Preview("Date picker") {
		let timeMachine = TimeMachine.solsticeTimeMachine
		timeMachine.interfaceState.datePickerVisible = true

		return TimeTravelOrnamentView()
			.withTimeMachine(timeMachine)
	}
#endif
