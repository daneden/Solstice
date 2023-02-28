//
//  DetailView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import Solar
import CoreLocation
import TimeIntervalFormatStyle

struct DetailView<Location: ObservableLocation>: View {
	@Environment(\.managedObjectContext) var viewContext
	
	@Binding var navigationSelection: NavigationSelection?
	@ObservedObject var location: Location
	@EnvironmentObject var timeMachine: TimeMachine
	@State private var showRemainingDaylight = false
	@State private var timeTravelVisible = false
	
	var relativeDateFormatter: RelativeDateTimeFormatter {
		let formatter = RelativeDateTimeFormatter()
		formatter.dateTimeStyle = .named
		formatter.formattingContext = .standalone
		return formatter
	}
	
	var dateComponentsFormatter: DateComponentsFormatter {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		return formatter
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
	
	var body: some View {
		GeometryReader { geom in
			Form {
#if os(iOS)
				TimeMachineView()
#endif
				Section {
					if let solar = solar {
						DaylightChart(solar: solar, timeZone: location.timeZone)
							.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
							.frame(height: chartHeight)
							.padding(.bottom)
#if os(watchOS)
							.listRowBackground(Color.clear)
#endif
					}
					
					LabeledContent {
						Text("\(sunrise.distance(to: sunset).formatted(.timeInterval()))")
					} label: {
						Label("Total Daylight", systemImage: "hourglass")
					}
					
					LabeledContent {
						Text("\(sunrise, style: .time)")
					} label: {
						Label("Sunrise", systemImage: "sunrise")
					}
					
					if let culmination = solar?.peak.withTimeZoneAdjustment(for: timeZone) {
						LabeledContent {
							Text("\(culmination, style: .time)")
						} label: {
							Label("Culmination", systemImage: "sun.max")
						}
					}
					
					LabeledContent {
						Text("\(sunset, style: .time)")
					} label: {
						Label("Sunset", systemImage: "sunset")
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
							LabeledContent {
								Text(relativeDateFormatter.localizedString(for: nextSolstice, relativeTo: date))
							} label: {
								Label("Next Solstice", systemImage: nextGreaterThanPrevious ? "sun.max" : "sun.min")
							}
							
							Text("\(dateComponentsFormatter.string(from: daylightDifference) ?? "") \(nextGreaterThanPrevious ? "more" : "less") daylight on this day compared to the previous solstice")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						LabeledContent {
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
							withAnimation {
								if let id = try? location.saveLocation(to: viewContext) {
									navigationSelection = .savedLocation(id: id)
								}
							}
						} label: {
							Label("Add", systemImage: "plus.circle")
						}
					}
				}
			}
#endif
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
}

struct DetailView_Previews: PreviewProvider {
	static var previews: some View {
		DetailView(
			navigationSelection: .constant(nil),
			location: CurrentLocation()
		)
	}
}
