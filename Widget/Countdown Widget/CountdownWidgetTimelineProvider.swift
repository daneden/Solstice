//
//  CountdownWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import Foundation
import WidgetKit
import CoreLocation

struct CountdownWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	static let widgetKind: SolsticeWidgetKind = .CountdownWidget
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Countdown")
		]
	}
}
