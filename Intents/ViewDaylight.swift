//
//  ViewDaylight.swift
//  Solstice
//
//  Created by Daniel Eden on 01/03/2023.
//

import Foundation
import AppIntents
import CoreLocation
import Solar

struct ViewDaylight: AppIntent {
	static var title: LocalizedStringResource = "View Daylight"
	static var description = IntentDescription("View how much daylight there is on a given day, based on the duration from that day’s sunrise to sunset.")
	
	@Parameter(title: "Date")
	var date: Date
	
	@Parameter(title: "Location")
	var location: CLPlacemark
	
	static var parameterSummary: some ParameterSummary {
		Summary("Get the daylight duration on \(\.$date) in \(\.$location)")
	}
	
	func perform() async throws -> some IntentResult & ReturnsValue<TimeInterval> & ProvidesDialog {
		guard let coordinate = location.location?.coordinate else {
			throw $location.needsValueError("What location do you want to see the daylight for?")
		}
		
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		formatter.allowedUnits = [.hour, .minute, .second]
		
		let solar = Solar(for: date, coordinate: coordinate)
		
		let duration = (solar?.sunrise ?? .now).distance(to: solar?.sunset ?? .now)
		
		return .result(
			value: duration,
			dialog: "\(formatter.string(from: duration) ?? "") of daylight on \(date.formatted(date: .abbreviated, time: .omitted))"
		)
	}
}

extension ViewDaylight: CustomIntentMigratedAppIntent {
	static var intentClassName = "ViewDaylightTimeIntent"
}
