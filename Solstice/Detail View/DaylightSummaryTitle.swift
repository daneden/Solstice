//
//  DaylightSummaryTitle.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar

struct DaylightSummaryTitle: View {
	var solar: Solar
	var event: Solar.Event?
	var currentX: Date?
	
	var summaryFont: Font {
#if os(watchOS)
		.headline
#elseif os(macOS)
		.title
#else
		.title2
#endif
	}
	
    var body: some View {
			VStack(alignment: .leading) {
				HStack {
					Text(solar.differenceString)
						.font(summaryFont)
						.fontWeight(.semibold)
						.lineLimit(10)
					Spacer(minLength: 0)
				}
				.opacity(event == nil ? 1 : 0)
				.overlay(alignment: .leading) {
					if let event {
						HStack {
							VStack(alignment: .leading) {
								Text(event.label)
								Text(event.date, style: .time)
									.foregroundStyle(.secondary)
							}
							
							Spacer()
							
							if let currentX {
								VStack(alignment: .trailing) {
									Text(currentX, style: .time)
										.foregroundStyle(.secondary)
									
									Group {
										if currentX < solar.safeSunrise {
											Text("Sunrise in \(timeIntervalFormatter.string(from: currentX.distance(to: solar.safeSunrise))!)")
										} else if currentX < solar.safeSunset {
											Text("Sunset in \(timeIntervalFormatter.string(from: currentX.distance(to: solar.safeSunset))!)")
										} else if currentX > solar.safeSunset {
											Text("Sunrise in \(timeIntervalFormatter.string(from: currentX.distance(to: solar.tomorrow?.safeSunrise ?? solar.endOfDay))!)")
										}
									}
									.foregroundStyle(.tertiary)
								}
							}
						}
					}
				}
			}
#if !os(macOS)
			.padding()
#endif
			.fontDesign(.rounded)
			.fontWeight(.semibold)
    }
}

struct DaylightSummaryTitle_Previews: PreviewProvider {
    static var previews: some View {
			DaylightSummaryTitle(solar: Solar(coordinate: TemporaryLocation.placeholderLocation.coordinate.coordinate)!)
    }
}
