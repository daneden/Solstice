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
#if os(iOS)
				TimeMachineView()
#endif
				Section {
					daylightChartView
						.contextMenu {
							if let chartRenderedAsImage {
								ShareLink(
									item: chartRenderedAsImage,
									preview: SharePreview("Daylight in \(location.title ?? "my location")", image: chartRenderedAsImage)
								)
							}
						}
					
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
								Text(relativeDateFormatter.localizedString(for: nextSolstice, relativeTo: date))
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
							Text(relativeDateFormatter.localizedString(for: nextEquinox, relativeTo: date))
						} label: {
							Label("Next Equinox", systemImage: "circle.and.line.horizontal")
						}
					}
					
					AnnualDaylightChart(location: location)
						.frame(height: chartHeight)
				}
			}
			.formStyle(.grouped)
#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
#endif
			.navigationTitle(location.title ?? "Solstice")
#if !os(watchOS)
			.toolbar {
				ToolbarItem(id: "timeMachineToggle") {
					Toggle(isOn: $timeMachine.isOn.animation()) {
						Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
					}
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
#endif
		}
	}
	
	var chartRenderedAsImage: Image? {
		let imageRenderer = ImageRenderer(content: daylightChartView)
		imageRenderer.scale = 2
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
	
	var daylightChartView: some View {
		Group {
			if let solar = solar {
				DaylightChart(
					solar: solar,
					timeZone: location.timeZone,
					scrubbable: true,
					markSize: chartMarkSize
				)
				.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
				.frame(height: chartHeight)
				.padding(.bottom)
#if os(macOS) || os(iOS)
				.blendMode(.plusLighter)
				.background(
					LinearGradient(colors: SkyGradient.getCurrentPalette(for: solar), startPoint: .top, endPoint: .bottom)
						.padding(-12)
				)
				.colorScheme(.dark)
#elseif os(watchOS)
				.listRowBackground(Color.clear)
#endif
			}
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
#if os(iOS)
		300
#elseif os(macOS)
		300
#elseif os(watchOS)
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
