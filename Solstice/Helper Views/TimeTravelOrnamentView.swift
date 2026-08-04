//
//  TimeTravelOrnamentView.swift
//  Solstice
//
//  Created by Daniel Eden on 04/08/2026.
//

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
						Group {
							if #available(visionOS 2, macOS 26, *) {
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
							} else {
								Slider(value: $timeMachine.offset, in: timeMachine.range) {
									Text("Offset")
								} minimumValueLabel: {
									Text("-6mo")
										.fixedSize()
								} maximumValueLabel: {
									Text("+6mo")
										.fixedSize()
								}
							}
						}
						.labelsHidden()
						#if os(macOS)
						.frame(width: 160)
						#else
						.frame(width: 280)
						#endif

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
			#if os(visionOS)
			.padding(16)
			.glassBackgroundEffect(in: .capsule)
			#else
			.padding(8)
			.backportGlassEffect(in: .capsule)
			#endif
			.animation(.default, value: timeMachine.interfaceState.datePickerVisible)
			#if os(macOS)
			.fixedSize(horizontal: false, vertical: true)
			.frame(maxWidth: .infinity, alignment: .trailing)
			.scenePadding()
			#endif
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
