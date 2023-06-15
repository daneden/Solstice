//
//  CountdownWidgetView+AccessoryWidgetViews.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import SwiftUI
import Solar
import WidgetKit

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
		
		var previousEvent: Solar.Event
		var nextEvent: Solar.Event
		
		var body: some View {
			ZStack {
				VStack {
					Image(systemName: nextEvent.imageName)
					Text(nextEvent.date.formatted(.dateTime.hour(.conversationalDefaultDigits(amPM: .omitted)).minute()))
						.allowsTightening(true)
				}
				.font(.caption.weight(.semibold))
				.foregroundStyle(.white)
				
				ProgressView(timerInterval: previousEvent.date...nextEvent.date) {
					nextEventText
				} currentValueLabel: {
					
				}
				.progressViewStyle(.circular)
				.tint(widgetRenderingMode == .fullColor ? Color("AccentColor") : .accentColor)
				.widgetAccentable(widgetRenderingMode != .fullColor)
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
						.transition(.move(edge: .bottom))
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
		var nextEvent: Solar.Event
		
		var body: some View {
			Image(systemName: nextEvent.imageName)
				.font(.title.bold())
				.symbolVariant(.fill)
				.imageScale(.large)
				.widgetLabel {
					Text("\(nextEvent.date, style: .time), \(nextEvent.date, style: .relative)")
				}
		}
	}
}
