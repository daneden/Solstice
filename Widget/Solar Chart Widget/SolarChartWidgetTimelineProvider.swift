//
//  SolarChartWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 12/04/2023.
//

import Foundation
import WidgetKit
import CoreLocation

struct SolarChartWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	static let widgetKind: SolsticeWidgetKind = .SolarChartWidget
	internal let currentLocation = CurrentLocation()
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Solar Chart"),
		]
	}
}
