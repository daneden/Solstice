//
//  ShareSolarChartView.swift
//  Solstice
//
//  Created by Daniel Eden on 04/03/2025.
//

import SwiftUI
import Suite
import TimeMachine

struct ShareSolarChartView<Location: AnyLocation>: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	
	var solar: NTSolar
	var location: Location
	
	@State var chartAppearance: DaylightChart.Appearance = .graphical
	@State var chartRenderedAsImage: Image?
	@State var imageData: Data?
	
	@State var showLocationName = true
	
	var animated: Bool {
		chartRenderedAsImage != nil
	}
	
	@ViewBuilder
	var daylightChartView: some View {
		DaylightChart(
			solar: solar,
			timeZone: location.timeZone,
			appearance: chartAppearance, scrubbable: true,
			markSize: chartMarkSize
		)
		.if(chartAppearance == .graphical) { content in
			content
				.background {
				SkyGradient(ntSolar: solar)
				}
		}
	}
	
	var deps: [AnyHashable] {
		[showLocationName, solar.date, location, chartAppearance]
	}
	
	private let igStoriesUrl: URL? = URL(string: "instagram-stories://share?source_application=me.daneden.Solstice")
	
	private var displayIgShareButton: Bool {
		guard let igStoriesUrl else { return false }
		
		if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
			return true
		}
		
#if os(iOS)
		return UIApplication.shared.canOpenURL(igStoriesUrl)
#else
		return false
#endif
	}
	
	var body: some View {
		NavigationStack {
			List {
				mainListContent
			}
			.listStyle(.plain)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark") {
						dismiss()
					}
				}
			}
			.navigationTitle("Share image")
			.task(id: deps) {
				self.chartRenderedAsImage = buildChartRenderedAsImage()
			}
		}
	}

	@ViewBuilder
	private var mainListContent: some View {
		Group {
			appearancePicker
			chartPreview
			locationToggle
			shareSection
		}
		#if !os(watchOS)
		.listRowSeparator(.hidden)
		#endif
	}

	private var appearancePicker: some View {
		Picker(selection: $chartAppearance) {
			ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
				Text(appearance.description)
			}
		} label: {
			Text("Chart appearance")
		}
		#if !os(watchOS)
		.pickerStyle(.segmented)
		#endif
	}

	private var chartPreview: some View {
		VStack {
			if let chartRenderedAsImage {
				chartRenderedAsImage
					.resizable()
					.aspectRatio(contentMode: .fit)
					.shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
			} else {
				ProgressView()
			}
		}
		.frame(height: 360)
		.frame(maxWidth: .infinity, alignment: .center)
		.padding(.bottom)
	}

	private var locationToggle: some View {
		Toggle(isOn: $showLocationName) {
			Label("Show location", systemImage: showLocationName ? "location" : "location.slash")
				.contentTransition(.symbolEffect(.replace))
		}
	}

	private var shareSection: some View {
		Section {
			shareButtons
				.foregroundStyle(.tint)
				#if !os(watchOS)
				.listRowSeparator(.visible)
				#endif
		}
	}

	@ViewBuilder
	private var shareButtons: some View {
#if os(iOS)
		instagramShareButton
#endif
		standardShareLink
	}

#if os(iOS)
	@ViewBuilder
	private var instagramShareButton: some View {
		let solarGradient = SkyGradient(ntSolar: solar)
		if let igStoriesUrl,
			 let imageData,
			 let topColor = solarGradient.stops.first?.toHex(),
			 let bottomColor = solarGradient.stops.last?.toHex(),
			 displayIgShareButton {
			Button {
				let pasteboardItems: [[String: Any]] = [[
					"com.instagram.sharedSticker.stickerImage": imageData,
					"com.instagram.sharedSticker.backgroundTopColor": topColor,
					"com.instagram.sharedSticker.backgroundBottomColor": bottomColor
				]]

				UIPasteboard.general.setItems(pasteboardItems, options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
				UIApplication.shared.open(igStoriesUrl)
			} label: {
				Label {
					Text("Share to Instagram Story")
				} icon: {
					Image(.instagram)
				}
			}
		}
	}
#endif

	@ViewBuilder
	private var standardShareLink: some View {
		if let chartRenderedAsImage {
			let title: String = location.title ?? "Current Location"
			ShareLink(
				item: chartRenderedAsImage,
				preview: SharePreview("Daylight in \(title)", image: chartRenderedAsImage)
			)
		}
	}
	
	func buildChartRenderedAsImage() -> Image? {
		@ViewBuilder
		var footer: some View {
			Group {
				if showLocationName {
					HStack {
						VStack(alignment: .leading) {
							Group {
								if let title = location.title {
									Text(title)
								} else {
									Text("Current Location")
								}
							}
							.font(.headline)
							
							let duration = solar.daylightDuration.localizedString
							Text("\(duration) of daylight")
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						VStack(alignment: .trailing) {
							Label("\(solar.safeSunrise, style: .time)", systemImage: "sunrise")
							Label("\(solar.safeSunset, style: .time)", systemImage: "sunset")
						}
						.foregroundStyle(.secondary)
					}
				} else {
					VStack(alignment: .leading) {
						let duration = solar.daylightDuration.localizedString
						Text("\(duration) of daylight")
							.font(.headline)
						
						Label("\(solar.safeSunrise...solar.safeSunset)", systemImage: "sun.max")
							.foregroundStyle(.secondary)
					}
				}
			}
			.environment(\.timeZone, location.timeZone)
		}
		let view = VStack(alignment: .leading, spacing: 0) {
			HStack {
				Label("Solstice", image: "solstice")
					.font(.headline)
				
				Spacer()
				
				Text(Date(), style: .date)
					.foregroundStyle(.secondary)
			}
				.scenePadding()
			
			daylightChartView
			
			footer
				.scenePadding()
		}
			.background(in: .rect(cornerRadius: 20, style: .continuous))
			.frame(width: 420, height: 525)
		
		let imageRenderer = ImageRenderer(content: view)
		imageRenderer.scale = 3
		imageRenderer.isOpaque = false
		
#if os(macOS)
		guard let image = imageRenderer.nsImage,
					let data = image.pngData(),
					let nsImage = NSImage(data: data) else {
			return nil
		}
		
		imageData = data
		
		return Image(nsImage: nsImage)
#else
		guard let image = imageRenderer.uiImage,
					let data = image.pngData(),
					let uiImage = UIImage(data: data) else {
			return nil
		}
		
		imageData = data
		
		return Image(uiImage: uiImage)
#endif
	}
}

#Preview {
	ShareSolarChartView(solar: .init(for: .now, coordinate: TemporaryLocation.placeholderLondon.coordinate, timeZone: TemporaryLocation.placeholderLondon.timeZone)!, location: TemporaryLocation.placeholderLondon)
		.withTimeMachine(.solsticeTimeMachine)
}
