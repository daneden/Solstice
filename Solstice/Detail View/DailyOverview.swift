//
//  DailyOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 12/03/2023.
//

import SwiftUI
import Solar

struct DailyOverview<Location: AnyLocation>: View {
	@EnvironmentObject var timeMachine: TimeMachine

	var solar: Solar
	var location: Location
	
	@State var chartRenderedAsImage: Image?
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	
	var solarDateIsInToday: Bool {
		var calendar = Calendar.autoupdatingCurrent
		calendar.timeZone = location.timeZone
		return calendar.isDate(solar.date, inSameDayAs: Date())
	}
	
	var body: some View {
		Section {
			daylightChartView
				.frame(height: chartHeight)
				.contextMenu {
					if let chartRenderedAsImage {
						ShareLink(
							item: chartRenderedAsImage,
							preview: SharePreview("Daylight in \(location.title ?? "my location")", image: chartRenderedAsImage)
						)
					}

					#if !os(watchOS)
					Picker(selection: $chartAppearance.animation()) {
						ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
							Text(appearance.rawValue)
						}
					} label: {
						Label("Appearance", systemImage: "paintpalette")
					}
					#endif
				}
				.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
				#if os(watchOS)
				.listRowBackground(Color.clear)
				#endif
			
			AdaptiveLabeledContent {
				Text(Duration.seconds(solar.safeSunrise.distance(to: solar.safeSunset)).formatted(.units(maximumUnitCount: 2)))
			} label: {
				Label("Total Daylight", systemImage: "hourglass")
			}
			
			if solarDateIsInToday && (solar.safeSunrise...solar.safeSunset).contains(solar.date) {
				AdaptiveLabeledContent {
					Text(timerInterval: solar.safeSunrise...solar.safeSunset)
						.monospacedDigit()
				} label: {
					Label("Remaining Daylight", systemImage: "timer")
				}
			}
			
			AdaptiveLabeledContent {
				Text("\(solar.safeSunrise, style: .time)")
			} label: {
				Label("Sunrise", systemImage: "sunrise")
			}
			
			let culmination = solar.peak.withTimeZoneAdjustment(for: location.timeZone)
			AdaptiveLabeledContent {
				Text("\(culmination, style: .time)")
			} label: {
				Label("Culmination", systemImage: "sun.max")
			}
			
			AdaptiveLabeledContent {
				Text("\(solar.safeSunset, style: .time)")
			} label: {
				Label("Sunset", systemImage: "sunset")
			}
		} header: {
			if location.timeZoneIdentifier != TimeZone.autoupdatingCurrent.identifier,
				 !(location is CurrentLocation) {
				HStack {
					Text("Local Time")
					Spacer()
					Text("\(solar.date.withTimeZoneAdjustment(for: location.timeZone), style: .time) (\(location.timeZone.differenceStringFromLocalTime(for: timeMachine.date)))")
				}
			}
		}
		.task(id: timeMachine.date, priority: .background) {
			chartRenderedAsImage = buildChartRenderedAsImage()
		}
	}
}

extension DailyOverview {
	func buildChartRenderedAsImage() -> Image? {
		let view = VStack {
			HStack {
				Label("Solstice", image: "Solstice.SFSymbol")
					.font(.headline)
				
				Spacer()
			}
			.padding()
			
			daylightChartView
				.clipShape(
					RoundedRectangle(
						cornerRadius: 16,
						style: .continuous
					)
				)
				.if(chartAppearance == .graphical) { view in
					view.padding(.horizontal)
				}
			
			
			HStack {
				VStack(alignment: .leading) {
					Text(location.title ?? "My Location")
						.font(.headline)
					
					let duration = solar.daylightDuration.localizedString
					Text("\(duration) of daylight")
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				VStack(alignment: .trailing) {
					Text("Sunrise: \(solar.safeSunrise, style: .time)")
					
					Text("Sunset: \(solar.safeSunset, style: .time)")
				}
				.foregroundStyle(.secondary)
			}
			.padding()
		}
			.background(.black)
			.foregroundStyle(.white)
			.clipShape(
				RoundedRectangle(
					cornerRadius: 20,
					style: .continuous
				)
			)
			.frame(width: 540, height: 720)
		
		let imageRenderer = ImageRenderer(content: view)
		imageRenderer.scale = 3
		imageRenderer.isOpaque = false
#if os(macOS)
		guard let image = imageRenderer.nsImage else {
			return nil
		}
		
		return Image(nsImage: image)
#else
		guard let image = imageRenderer.uiImage else {
			return nil
		}
		
		return Image(uiImage: image)
#endif
	}
	
	@ViewBuilder
	var daylightChartView: some View {
		DaylightChart(
			solar: solar,
			timeZone: location.timeZone,
			appearance: chartAppearance, scrubbable: true,
			markSize: chartMarkSize
		)
	}
}

struct DailyOverview_Previews: PreviewProvider {
	static var previews: some View {
		Form {
			DailyOverview(solar: Solar(coordinate: TemporaryLocation.placeholderLondon.coordinate.coordinate)!, location: TemporaryLocation.placeholderLondon)
		}
		.environmentObject(TimeMachine.preview)
	}
}
