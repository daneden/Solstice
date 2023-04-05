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
		var previousEvent: Solar.Event
		var nextEvent: Solar.Event
		
		var body: some View {
			ProgressView(timerInterval: previousEvent.date...nextEvent.date) {
				nextEventText
			} currentValueLabel: {
				VStack {
					Image(systemName: nextEvent.imageName)
					Text(nextEvent.date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()))
						.allowsTightening(true)
				}
				.font(.caption)
			}
			.progressViewStyle(.circular)
			.tint(.accentColor)
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
					Text(nextEvent.date, style: .relative)
					Text(nextEvent.date, style: .time)
						.foregroundColor(.secondary)
				}
				
				Spacer(minLength: 0)
			}
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
