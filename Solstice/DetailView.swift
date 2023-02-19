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

struct DetailView<Location: AnyLocation>: View {
	@ObservedObject var location: Location
	@EnvironmentObject var timeMachine: TimeMachine
	@State private var showRemainingDaylight = false
	@State private var timeTravelVisible = false
	
	var body: some View {
		GeometryReader { geom in
			Form {
#if !os(macOS) && !os(watchOS)
				TimeMachineView()
#endif
				Section {
					if let solar = solar {
						DaylightChart(solar: solar, timeZone: location.timeZone)
							.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
							.frame(minHeight: 200, idealHeight: geom.size.height * 0.4)
							.padding(.bottom)
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
					
					if let culmination = solar?.peak {
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
					
					AnnualDaylightChart(location: location)
						.frame(minHeight: geom.size.height * 0.4)
						.padding(.vertical)
				}
			}
			.formStyle(.grouped)
			.navigationTitle(location.title ?? "Solstice")
#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
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
		return returnValue.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: date)))
	}
	
	var sunset: Date {
		let returnValue = solar?.safeSunset ?? .now
		return returnValue.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: date)))
	}
}

struct DetailView_Previews: PreviewProvider {
	static var previews: some View {
		DetailView(location: CurrentLocation())
	}
}
