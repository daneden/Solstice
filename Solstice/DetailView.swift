//
//  DetailView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import Solar
import CoreLocation


struct DetailView<Location: ObservableLocation>: View {
	@Environment(\.managedObjectContext) var viewContext
	@Environment(\.dismiss) var dismiss
	
	@ObservedObject var location: Location
	@EnvironmentObject var timeMachine: TimeMachine
	@EnvironmentObject var navigationState: NavigationStateManager
	@State private var showRemainingDaylight = false
	@State private var timeTravelVisible = false
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	
	var body: some View {
		GeometryReader { geom in
			Form {
				#if !os(watchOS)
				if timeMachine.isOn {
					TimeMachineView()
				}
				#endif
				Section {
					daylightChartView
						.frame(height: chartHeight)
						.contextMenu {
							#if !os(tvOS)
							if let chartRenderedAsImage {
								ShareLink(
									item: chartRenderedAsImage,
									preview: SharePreview("Daylight in \(location.title ?? "my location")", image: chartRenderedAsImage)
								)
							}
							#endif
							
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
						Text("\(timeIntervalFormatter.string(from: sunrise.distance(to: sunset)) ?? "")")
					} label: {
						Label("Total Daylight", systemImage: "hourglass")
					}
					
					AdaptiveLabeledContent {
						Text("\(sunrise, style: .time)")
					} label: {
						Label("Sunrise", systemImage: "sunrise")
					}
					
					if let culmination = solar?.peak.withTimeZoneAdjustment(for: timeZone) {
						AdaptiveLabeledContent {
							Text("\(culmination, style: .time)")
						} label: {
							Label("Culmination", systemImage: "sun.max")
						}
					}
					
					AdaptiveLabeledContent {
						Text("\(sunset, style: .time)")
					} label: {
						Label("Sunset", systemImage: "sunset")
					}
				} header: {
					if location.timeZoneIdentifier != TimeZone.autoupdatingCurrent.identifier,
						 !(location is CurrentLocation),
						 let date = solar?.date {
						HStack {
							Text("Local Time")
							Spacer()
							Text("\(date.withTimeZoneAdjustment(for: location.timeZone), style: .time) (\(timeZone.differenceStringFromLocalTime(for: timeMachine.date)))")
						}
					}
				}
				
				Section {
					if let date = solar?.date,
						 let nextSolstice = solar?.date.nextSolstice,
						 let prevSolstice = solar?.date.previousSolstice,
						 let nextEquinox = solar?.date.nextEquinox,
						 let nextSolsticeSolar = Solar(for: nextSolstice, coordinate: solar?.coordinate ?? .init()),
						 let previousSolsticeSolar = Solar(for: prevSolstice, coordinate: solar?.coordinate ?? .init()) {
						let daylightDifference = abs((solar?.daylightDuration ?? 0) - previousSolsticeSolar.daylightDuration)
						let nextGreaterThanPrevious = nextSolsticeSolar.daylightDuration > previousSolsticeSolar.daylightDuration
						
						VStack(alignment: .leading) {
							AdaptiveLabeledContent {
								if nextSolstice.startOfDay == date.startOfDay {
									Text("Today")
								} else {
									Text(relativeDateFormatter.localizedString(for: nextSolstice.startOfDay, relativeTo: date.startOfDay))
								}
							} label: {
								Label("Next Solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
							}
							
							Label {
								Text("\(timeIntervalFormatter.string(from: daylightDifference) ?? "") \(nextGreaterThanPrevious ? "more" : "less") daylight on this day compared to the previous solstice")
									.font(.caption)
									.foregroundStyle(.secondary)
							} icon: {
								Color.clear.frame(width: 0, height: 0)
							}
						}
						
						AdaptiveLabeledContent {
							if nextEquinox.startOfDay == date.startOfDay {
								Text("Today")
							} else {
								Text(relativeDateFormatter.localizedString(for: nextEquinox.startOfDay, relativeTo: date.startOfDay))
							}
						} label: {
							Label("Next Equinox", systemImage: "circle.and.line.horizontal")
						}
					}
					
					AnnualDaylightChart(location: location)
						.frame(height: chartHeight)
				}
			}
			.formStyle(.grouped)
			.navigationTitle(location.title ?? "Solstice")
			.toolbar {
				toolbarItems
			}
		}
	}
	
	@ToolbarContentBuilder
	var toolbarItems: some ToolbarContent {
		ToolbarItem(id: "timeMachineToggle") {
			#if os(watchOS)
			Button {
				timeMachine.controlsVisible.toggle()
			} label: {
				Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
			}
			.sheet(isPresented: $timeMachine.controlsVisible) {
				TimeMachineView()
			}
			#else
			Toggle(isOn: $timeMachine.isOn.animation()) {
				Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
			}
			#endif
			
		}
		
		ToolbarItem {
			if let location = location as? TemporaryLocation {
				Button {
					dismiss()
					withAnimation {
						if let id = try? location.saveLocation(to: viewContext) {
							navigationState.navigationSelection = .savedLocation(id: id)
						}
					}
				} label: {
					Label("Save Location", systemImage: "plus.circle")
				}
			}
		}
		
		if navigationState.temporaryLocation != nil {
			ToolbarItem(placement: .cancellationAction) {
				Button {
					navigationState.temporaryLocation = nil
				} label: {
					Text("Close")
				}
			}
		}
	}
	
	var chartRenderedAsImage: Image? {
		let view = VStack {
			HStack {
				Label {
					Text("Solstice")
				} icon: {
					Image("Solstice-Icon")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 16)
				}
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
					
					if let duration = solar?.daylightDuration.localizedString {
						Text("\(duration) of daylight")
							.foregroundStyle(.secondary)
					}
				}
				
				Spacer()
				
				VStack(alignment: .trailing) {
					Text("Sunrise: \(sunrise, style: .time)")
					
					Text("Sunset: \(sunset, style: .time)")
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
		if let solar = solar {
			DaylightChart(
				solar: solar,
				timeZone: location.timeZone,
				appearance: chartAppearance, scrubbable: true,
				markSize: chartMarkSize
			)
			.padding(.bottom)
		}
	}
}

extension DetailView {
	var date: Date {
		timeMachine.date
	}
	
	var solar: Solar? {
		Solar(for: date, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
	}
	
	var timeZone: TimeZone {
		guard let timeZoneIdentifier = location.timeZoneIdentifier,
					let specifiedTimeZone = TimeZone(identifier: timeZoneIdentifier) else {
			return .autoupdatingCurrent
		}
		
		return specifiedTimeZone
	}
	
	var sunrise: Date {
		let returnValue = solar?.safeSunrise ?? .now
		return returnValue.withTimeZoneAdjustment(for: timeZone)
	}
	
	var sunset: Date {
		let returnValue = solar?.safeSunset ?? .now
		return returnValue.withTimeZoneAdjustment(for: timeZone)
	}
	
	var chartHeight: CGFloat {
#if !os(watchOS)
		300
#else
		200
#endif
	}
	
	var chartMarkSize: Double {
#if os(watchOS)
		4
#else
		8
#endif
	}
}

struct DetailView_Previews: PreviewProvider {
	static var previews: some View {
		DetailView(location: TemporaryLocation.placeholderLocation)
		.environmentObject(TimeMachine())
		.environmentObject(NavigationStateManager())
	}
}
