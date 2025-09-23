//
//  TimeMachineOverlayView.swift
//  Solstice
//
//  Created by Daniel Eden on 20/05/2025.
//

import SwiftUI
import Suite
import TimeMachine

struct TimeMachineOverlayView: View {
	@Environment(\.colorScheme) private var colorScheme
	
	var body: some View {
		VStack {
			TimeMachineView(showAbsoluteTime: .never, datePickerComponents: .date) {
				Text("Time Travel")
			} relativeTimestampLabel: { t, _ in
				Text(t.date, format: .dateTime.day().month().year())
			} datePickerLabel: { _, _ in
				Text("Choose date")
			}
			#if os(visionOS)
				.frame(minWidth: 400)
			#endif
		}
		.padding()
		.clipped()
		#if os(visionOS)
		.glassBackgroundEffect(in: .rect(cornerRadius: 16, style: .continuous))
		#else
		.modify { content in
				if #available(iOS 26, macOS 26, *) {
					content
						.glassEffect(in: .rect(cornerRadius: 24, style: .continuous))
						.animation(.default.delay(0.2), value: colorScheme)
				} else {
					content
						.background(.regularMaterial, in: .rect(cornerRadius: 16, style: .continuous))
						.shadow(color: .black, radius: 12, x: 0, y: 8)
				}
			}
		.scenePadding(.horizontal)
		#if os(iOS)
		.background {
			if #unavailable(iOS 26) {
				VariableBlurView(maxBlurRadius: 1, direction: .blurredBottomClearTop)
					.background {
						Color.clear
							.background()
							.opacity(0.2)
							.mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
					}
					.ignoresSafeArea()
			}
		}
		#endif
		.scenePadding(.top)
		#endif
		#if os(macOS)
		.scenePadding(.bottom)
		#endif
	}
}

fileprivate enum TimeMachineDraggableBarAlignment: Int {
	case leading, trailing
}

struct TimeMachineDraggableOverlayView: View {
	@Environment(\.colorScheme) private var colorScheme
	
	@AppStorage("timeMachineDraggableBarAlignment") fileprivate
	var alignment: TimeMachineDraggableBarAlignment = .trailing
	
	private var resolvedAlignment: Alignment {
		switch alignment {
		case .leading:
			return .leading
		case .trailing:
			return .trailing
		}
	}
	
	@State private var measureScreenWidthTaskID = UUID()
	@State private var targetAlignment: TimeMachineDraggableBarAlignment = .trailing
	@State private var offset: CGSize = .zero
	@State private var screenSize: CGSize = .zero
	
	var screenWidth: Double { screenSize.width }
	
	private var barWidth: Double = 393
	
	private var threshold: Double {
		(screenWidth / 2) - (barWidth / 2)
	}
	
	var body: some View {
		ZStack(alignment: resolvedAlignment) {
			TimeMachineOverlayView()
				.offset(offset)
				.gesture(DragGesture()
					.onChanged { value in
						offset = value.translation
						
						switch alignment {
						case .leading:
							if offset.width >= threshold {
								targetAlignment = .trailing
							} else {
								targetAlignment = .leading
							}
						case .trailing:
							if offset.width * -1.0 >= threshold {
								targetAlignment = .leading
							} else {
								targetAlignment = .trailing
							}
						}
					}
					.onEnded { value in
						switch targetAlignment {
						case .leading:
							if value.predictedEndTranslation.width >= threshold {
								targetAlignment = .trailing
							}
							break
						case .trailing:
							if value.predictedEndTranslation.width * -1.0 >= threshold {
								targetAlignment = .leading
							}
							break
						}
						
						offset = .zero
						
						alignment = targetAlignment
					}
				)
				.frame(maxWidth: barWidth)
		}
		.frame(maxWidth: .infinity, alignment: resolvedAlignment)
		.readSize($screenSize)
		.background(alignment: .bottom) {
			HStack {
				CornerAnchorView(corner: .leading, isActive: targetAlignment == .leading)
				Spacer()
				CornerAnchorView(corner: .trailing, isActive: targetAlignment == .trailing)
			}
			#if !os(macOS)
			.scenePadding(.horizontal)
			#endif
			.blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
			.opacity(offset == .zero ? 0 : 1)
		}
		.animation(.snappy, value: offset)
		.animation(.smooth, value: alignment)
#if os(iOS)
		.onRotate { _ in
			measureScreenWidthTaskID = UUID()
		}
#endif
		.task {
			targetAlignment = alignment
		}
	}
}

fileprivate struct CornerAnchorView: View {
	var corner: TimeMachineDraggableBarAlignment
	var isActive = false
	
	var size: Double {
		#if os(macOS)
		isActive ? 32 : 24
		#else
		isActive ? 72 : 64
		#endif
	}
	
	var body: some View {
		Image(corner == .trailing ? .curveBottomTrailing : .curveBottomLeading)
			.resizable()
			.frame(width: size, height: size)
			.foregroundStyle(isActive ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
			#if os(macOS)
			.padding(12)
			#endif
	}
}
