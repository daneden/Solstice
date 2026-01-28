//
//  DaylightSummaryTitle.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import SunKit

struct DaylightSummaryTitle: View {
	var sun: Sun
	var event: Sun.Event?
	var date: Date?
	var timeZone = localTimeZone
	
	var summaryFont: Font {
		#if os(watchOS)
		.headline
		#elseif os(macOS)
		.title
		#else
		.title2
		#endif
	}
	
	var summaryLineLimit: Int {
		#if os(watchOS)
		4
		#else
		2
		#endif
	}
	
		private let formatter = Date.ComponentsFormatStyle.timeDuration
	
    var body: some View {
			VStack(alignment: .leading) {
				HStack {
					Text(sun.differenceString)
						.contentTransition(.numericText())
						.font(summaryFont)
						.fontWeight(.semibold)
						.lineLimit(summaryLineLimit)
						.allowsTightening(true)
						.minimumScaleFactor(0.8)
					Spacer(minLength: 0)
				}
				.opacity(event == nil ? 1 : 0)
				.overlay(alignment: .leading) {
					if let event {
						HStack {
							VStack(alignment: .leading) {
								Text(event.label)
									.contentTransition(.numericText(countsDown: true))
								Text(event.date, style: .time)
									.foregroundStyle(.secondary)
									.contentTransition(.numericText())
							}
							
							Spacer()
							
							if let date {
								VStack(alignment: .trailing) {
									Text(date, style: .time)
										.foregroundStyle(.secondary)
									
									Group {
										if date < sun.safeSunrise {
											Text("Sunrise in \((date..<sun.safeSunrise).formatted(formatter))")
										} else if date < sun.safeSunset {
											Text("Sunset in \((date..<sun.safeSunset).formatted(formatter))")
										} else if date > sun.safeSunset && date <= sun.tomorrow.safeSunrise {
											Text("Sunrise in \((date..<sun.tomorrow.safeSunrise).formatted(formatter))")
										}
									}
									.foregroundStyle(.tertiary)
								}
							}
						}
						.monospacedDigit()
					}
				}
			}
			#if !os(macOS)
			.scenePadding()
			#endif
			.fontDesign(.rounded)
			.fontWeight(.semibold)
			.environment(\.timeZone, timeZone)
			.animation(.smooth, value: event)
    }
}

struct DaylightSummaryTitle_Previews: PreviewProvider {
    static var previews: some View {
			DaylightSummaryTitle(sun: Sun(coordinate: TemporaryLocation.placeholderLondon.coordinate))
    }
}
