//
//  OverviewWidgetTimelineProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 03/04/2023.
//

import Foundation
import WidgetKit
import CoreLocation

struct OverviewWidgetTimelineProvider: SolsticeWidgetTimelineProvider {
	static let widgetKind: SolsticeWidgetKind = .OverviewWidget
	internal let currentLocation = CurrentLocation()
	internal let geocoder = CLGeocoder()
	
	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		let chartAppearanceConfiguration = ConfigurationIntent()
		chartAppearanceConfiguration.rectangularWidgetDisplaysChart = true as NSNumber
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "Overview"),
			IntentRecommendation(intent: chartAppearanceConfiguration, description: "Graphical Overview"),
		]
	}
}
