//
//  TimeTravelCompactView.swift
//  Solstice
//
//  Created by Dan Eden on 23/09/2025.
//

import SwiftUI
import TimeMachine
import Suite

extension Shape where Self == RoundedRectangle {
	static var panel: RoundedRectangle {
		RoundedRectangle(cornerRadius: 24, style: .continuous)
	}
}

struct TimeTravelViewOverlaySizePreferenceKey: PreferenceKey {
	static func reduce(value: inout Double, nextValue: () -> Double) {
		value = nextValue()
	}
	
	static var defaultValue = Double(0)
}

struct _TimeTravelCompactView: View {
	@Environment(\.timeMachine) private var timeMachine
	@AppStorage("isOffscreen") var isOffscreen = false
	@State private var sheetContentSize = CGSize.zero
	@State private var timeMachineViewSize = CGSize.zero
	
	var insetSize: Double {
		isOffscreen ? 0 : sheetContentSize.height
	}
	
	var body: some View {
		HStack(spacing: 16) {
			SolsticeTimeMachineView()
				.scenePadding([.leading, .vertical])
				.readSize($timeMachineViewSize)
			
			Button {
				withAnimation {
					isOffscreen.toggle()
				}
			} label: {
				Label("Toggle time travel", systemImage: isOffscreen ? "chevron.compact.right" : "chevron.compact.left")
					.imageScale(.large)
					.fontWeight(.bold)
					.padding(.horizontal, 8)
					.labelStyle(.iconOnly)
					.tint(.secondary)
					.frame(height: timeMachineViewSize.height)
					.background(.ultraThinMaterial)
					.animation(.default, value: timeMachineViewSize)
			}
		}
		.animation(.default, value: timeMachine.interfaceState.datePickerVisible)
		.clipShape(.panel)
		.modify {
			#if os(visionOS)
			$0
				.background(.regularMaterial, in: .panel)
				.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
				.transition(.blurReplace)
			#else
			if #available(iOS 26, watchOS 26, macOS 26, *) {
				$0.glassEffect(.regular.interactive(), in: .panel)
			} else {
				$0
					.background(.regularMaterial, in: .panel)
					.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
					.transition(.blurReplace)
			}
			#endif
		}
		.offset(x: isOffscreen ? -sheetContentSize.width + 44 : 0)
		.animation(.default, value: isOffscreen)
		.scenePadding()
		.readSize($sheetContentSize)
		.preference(key: TimeTravelViewOverlaySizePreferenceKey.self, value: insetSize)
		.animation(.default, value: insetSize)
	}
}

struct TimeTravelCompactView: View {
	@Environment(\.timeMachine) private var timeMachine
	@State private var isExpanded = false
	
	var body: some View {
		@Bindable var timeMachine = timeMachine
		
		BackportGlassEffectContainer {
			VStack {
				HStack {
					if isExpanded {
						Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
							.padding(6)
							.padding(.horizontal, 4)
							.modify {
								#if os(visionOS)
								$0.background(.regularMaterial, in: .capsule)
								#else
								if #available(iOS 26, macOS 26, watchOS 26, visionOS 26, *) {
									$0.glassEffect()
								} else {
									$0.background(.regularMaterial, in: .capsule)
								}
								#endif
							}
							.font(.subheadline)
						
						Spacer()
						
						Button("Reset", systemImage: "arrow.counterclockwise") {
							withAnimation {
								timeMachine.reset()
							}
						}
						.glassButtonStyle(timeMachine.isActive ? .prominent : .regular)
						.disabled(!timeMachine.isActive)
					} else {
						Spacer()
					}
					
					Button {
						withAnimation { isExpanded.toggle() }
					} label: {
						Label(
							isExpanded ? "Hide time travel" : "Show time travel",
							systemImage: isExpanded ? "xmark" : "clock.arrow.2.circlepath"
						)
						.padding(isExpanded ? 2 : 0)
					}
					.labelStyle(.iconOnly)
					.buttonBorderShape(.circle)
					.controlSize(isExpanded ? .small : .large)
					.glassButtonStyle(timeMachine.isActive && !isExpanded ? .prominent : .regular)
				}
				.controlSize(.small)
				.fontWeight(.medium)
				
				if isExpanded {
					HStack {
						Button("One week earlier", systemImage: "backward") {
							withAnimation { timeMachine.offset -= 7 }
						}
						.buttonStyle(CompactViewButtonStyle())
						
						DatePicker(selection: $timeMachine.date.animation(), displayedComponents: .date) {
							Text("Time travel to date")
						}
						.labelsHidden()
						.frame(maxWidth: .infinity)
						
						Button("One week later", systemImage: "forward") {
							withAnimation { timeMachine.offset += 7 }
						}
						.buttonStyle(CompactViewButtonStyle())
					}
					.padding(.vertical, 2)
					.padding(.horizontal, -2)
					.transition(.blurReplace)
					.modify {
						#if os(visionOS)
						$0.background(.regularMaterial, in: .capsule)
						#else
						if #available(iOS 26, macOS 26, watchOS 26, visionOS 26, *) {
							$0.glassEffect()
						} else {
							$0.background(.regularMaterial, in: .capsule)
						}
						#endif
					}
				}
			}
		}
		.modify {
			if #available(iOS 26, macOS 26, visionOS 26, watchOS 26, *) {
				$0
			} else {
				$0.shadow(color: .black.opacity(0.2), radius: 8, y: 4)
			}
		}
		.scenePadding()
		#if os(iOS)
		.background {
			if #unavailable(iOS 26) {
				VariableBlurView(maxBlurRadius: 1, direction: .blurredBottomClearTop)
			}
		}
		#endif
	}
}

struct TitleToggledLabelStyle: LabelStyle {
	var titleVisible: Bool
	
	func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.icon
			
			if titleVisible {
				configuration.title
					.transition(.blurReplace)
			}
		}
	}
}

struct CompactViewButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding()
			.buttonBorderShape(.circle)
			.labelStyle(.iconOnly)
			.symbolVariant(.fill)
			.background(.primary.opacity(configuration.isPressed ? 0.3 : 0), in: .circle)
			.font(.subheadline)
	}
}

struct BackportGlassEffectContainer<Content: View>: View {
	@ViewBuilder var content: Content
	
	var body: some View {
		#if os(visionOS)
		content
		#else
		if #available(iOS 26, macOS 26, watchOS 26, *) {
			GlassEffectContainer {
				content
			}
		} else {
			content
		}
		#endif
	}
}

#Preview {
	NavigationStack {
		List {
			
		}
		.navigationTitle("Test")
		.backportSafeAreaBar {
			TimeTravelCompactView()
				.scenePadding(.horizontal)
				.frame(maxWidth: .infinity, alignment: .trailing)
		}
	}
	.withTimeMachine(.solsticeTimeMachine)
}
