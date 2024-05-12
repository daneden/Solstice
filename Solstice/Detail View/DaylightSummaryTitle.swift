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
	
    var body: some View {
			VStack(alignment: .leading) {
				HStack {
					Text(solar.differenceString)
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
								Text(event.date, style: .time)
									.foregroundStyle(.secondary)
							}
							
							Spacer()
							
							if let currentX {
								VStack(alignment: .trailing) {
									Text(currentX, style: .time)
										.foregroundStyle(.secondary)
									
									Group {
										if currentX < solar.safeSunrise.withTimeZoneAdjustment(for: timeZone) {
											Text("Sunrise in \(formatDuration(currentX..<solar.safeSunrise.withTimeZoneAdjustment(for: timeZone)))")
										} else if currentX < solar.safeSunset.withTimeZoneAdjustment(for: timeZone) {
											Text("Sunset in \(formatDuration(currentX..<solar.safeSunset.withTimeZoneAdjustment(for: timeZone)))")
										} else if currentX > solar.safeSunset.withTimeZoneAdjustment(for: timeZone) {
											Text("Sunrise in \(formatDuration(currentX..<(solar.tomorrow?.safeSunrise.withTimeZoneAdjustment(for: timeZone) ?? solar.endOfDay.withTimeZoneAdjustment(for: timeZone))))")
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
			.scenePadding()
			#endif
			.fontDesign(.rounded)
			.fontWeight(.semibold)
    }
	
	func formatDuration(_ duration: Range<Date>) -> String {
		let timeInterval = duration.lowerBound.distance(to: duration.upperBound)
		return Duration.seconds(timeInterval)
			.formatted(.units(width: .narrow, maximumUnitCount: 2))
	}
}

struct DaylightSummaryTitle_Previews: PreviewProvider {
    static var previews: some View {
			DaylightSummaryTitle(solar: Solar(coordinate: TemporaryLocation.placeholderLondon.coordinate)!)
    }
}
