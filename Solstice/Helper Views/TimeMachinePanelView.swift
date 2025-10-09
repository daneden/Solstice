//
//  TimeMachineOverlayView.swift
//  Solstice
//
//  Created by Daniel Eden on 20/05/2025.
//

import SwiftUI
import Suite
import TimeMachine

struct SolsticeTimeMachineView: View {
	var body: some View {
		TimeMachineView(showAbsoluteTime: .never, datePickerComponents: .date) {
			Text("Time Travel")
		} relativeTimestampLabel: { t, _ in
			Text(t.date, format: .dateTime.day().month().year())
		} minimumValueLabel: { _, _ in
			Text("-12mo")
		} maximumValueLabel: { _, _ in
			Text("+12mo")
		} datePickerLabel: { _, _ in
			Text("Choose date")
		}
	}
}

struct TimeMachinePanelView: View {
	@Environment(\.colorScheme) private var colorScheme
	
	var body: some View {
		VStack {
			SolsticeTimeMachineView()
			#if os(visionOS)
				.frame(minWidth: 400)
			#endif
		}
		.padding()
		.clipShape(AnyShape.panel())
		#if os(visionOS)
		.glassBackgroundEffect(in: .rect(cornerRadius: 16, style: .continuous))
		#else
		.modify { content in
				if #available(iOS 26, macOS 26, *) {
					content
						.glassEffect(in: AnyShape.panel())
						.animation(.default.delay(0.2), value: colorScheme)
				} else {
					content
						.background(.regularMaterial.shadow(.drop(color: .black.opacity(0.2), radius: 8, y: 4)), in: AnyShape.panel())
				}
			}
		.scenePadding(.horizontal)
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
			TimeMachinePanelView()
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
