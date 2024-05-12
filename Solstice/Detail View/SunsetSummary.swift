//
//  SunsetSummary.swift
//  Solstice
//
//  Created by Daniel Eden on 29/01/2024.
//

import SwiftUI
// import Solar

struct SunsetSummary<Location: AnyLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
	var solar: Solar
	var location: Location
	
	var daylightIncreasing: Bool {
		solar.daylightDuration < (solar.tomorrow?.daylightDuration ?? 0)
	}
	
	var body: some View {
		if !timeMachine.isOn,
			 solar.date.isToday,
			 solar.safeSunset < timeMachine.date {
			Section {
				if let tomorrow = solar.tomorrow {
					ScrollView(.horizontal) {
						HStack {
							Group {
								Label {
									Text("\(Text(tomorrow.safeSunrise, style: .relative)) until sunrise")
								} icon: {
									Image(systemName: "sunrise")
										.foregroundStyle(Color.accentColor.gradient)
								}
								
								Label {
									Text(tomorrow.differenceString)
								} icon: {
									Image(systemName: daylightIncreasing ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
										.foregroundStyle(Color.accentColor.gradient)
								}
							}
							.labelStyle(SummaryCardLabelStyle())
							.frame(maxHeight: .infinity)
							.containerRelativeFrame(
								.horizontal,
								count: 3,
								span: 2,
								spacing: 8,
								alignment: .leading
							)
							.padding()
							#if os(iOS)
							.background(Color(UIColor.secondarySystemGroupedBackground))
							#endif
							.clipShape(.buttonBorder)
						}
					}
					.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
					.listRowBackground(Color.clear)
					
				}
			} header: {
				Label("Sunset Summary", image: "Solstice.SFSymbol")
			}
		}
	}
}

struct SummaryCardLabelStyle: LabelStyle {
	func makeBody(configuration: Configuration) -> some View {
		VStack(alignment: .leading) {
			configuration.icon
				.font(.title3)
			Spacer()
			configuration.title
		}
	}
}

#Preview {
	Form {
		SunsetSummary(
			solar: .init(coordinate: TemporaryLocation.placeholderLondon.coordinate)!,
			location: TemporaryLocation.placeholderLondon
		)
	}
	.environmentObject(TimeMachine.preview)
}
