//
//  CountdownWidgetView+AccessoryWidgetViews.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import SwiftUI
import Solar
import WidgetKit

#if !os(macOS)

extension CountdownWidgetView {
	struct AccessoryInlineView: View {
		var nextEvent: Solar.Event
		var body: some View {
			HStack {
				Image(systemName: nextEvent.imageName)
				Text("\(nextEvent.date, style: .time), \(nextEvent.date, style: .relative)")
			}
		}
	}
	
	struct AccessoryCircularView: View {
		@Environment(\.widgetRenderingMode) var widgetRenderingMode
		
		var entryDate: Date
		
		var previousEvent: Solar.Event
		var nextEvent: Solar.Event
		
		@ViewBuilder
		var currentValueLabel: some View {
			let duration = entryDate.distance(to: nextEvent.date)
			if duration >= 60 * 60 {
				Text(Duration.seconds(duration).formatted(.units(width: .narrow, maximumUnitCount: 1)))
			} else {
				Text(nextEvent.date, style: .timer)
					.monospacedDigit()
			}
		}
		
		var body: some View {
			ZStack {
				ProgressView(timerInterval: previousEvent.date...nextEvent.date) {
					nextEventText
				} currentValueLabel: {
					VStack {
						Image(systemName: nextEvent.imageName)
						currentValueLabel
					}
					.font(.caption)
				}
				.progressViewStyle(.circular)
				.tint(Color.accentColor)
				.widgetAccentable()
			}
			.widgetLabel { nextEventText }
		}
		
		var nextEventText: some View {
			Text("\(nextEvent.description.localizedCapitalized) in \(Text(nextEvent.date, style: .relative))")
		}
	}
	
	struct AccessoryRectangularView: View {
		var nextEvent: Solar.Event
		
		var body: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("\(Image(systemName: nextEvent.imageName)) \(nextEvent.label)")
						.font(.headline)
						.widgetAccentable()
						.imageScale(.small)
						.transition(.blurReplace)
					Text(nextEvent.date, style: .relative)
						.contentTransition(.numericText())
					Text(nextEvent.date, style: .time)
						.foregroundColor(.secondary)
						.contentTransition(.numericText())
				}
				
				Spacer(minLength: 0)
			}
			.animation(.default, value: nextEvent)
		}
	}
	
	struct AccessoryCornerView: View {
		var previousEvent: Solar.Event
		var nextEvent: Solar.Event
		
		var body: some View {
			Label {
				Text("\(Text(nextEvent.date, style: .time)), \(Text(nextEvent.date, style: .relative))")
			} icon: {
				Image(systemName: nextEvent.imageName)
			}
			.modify {
				if #available(iOSApplicationExtension 17.0, watchOSApplicationExtension 10.0, *) {
					$0.widgetCurvesContent()
				} else {
					$0
				}
			}
			.widgetLabel {
				ProgressView(timerInterval: previousEvent.date...nextEvent.date) {
					Image(systemName: previousEvent.imageName)
				} currentValueLabel: {
					Label {
						Text("\(Text(nextEvent.date, style: .timer)) until \(Text(nextEvent.description))")
					} icon: {
						Image(systemName: nextEvent.imageName)
					}
				}
			}
		}
	}
}

#Preview(
	"Countdown (Accessory Rectangular)",
	as: WidgetFamily.accessoryRectangular,
	widget: { CountdownWidget() },
	timeline: SolsticeWidgetTimelineEntry.previewTimeline
)

#endif
