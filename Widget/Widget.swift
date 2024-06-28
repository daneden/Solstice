//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 19/02/2023.
//

import Foundation
import CoreLocation

struct SolsticeWidgetLocation: AnyLocation {
	var title: String?
	var subtitle: String?
	var timeZoneIdentifier: String?
	var latitude: Double
	var longitude: Double
	var isRealLocation = false
	var locationUUID: UUID?
	
	var timeZone: TimeZone {
		guard let timeZoneIdentifier else { return .autoupdatingCurrent }
		return TimeZone(identifier: timeZoneIdentifier) ?? .autoupdatingCurrent
	}
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	static let defaultLocation = SolsticeWidgetLocation(title: "London",
																											subtitle: "United Kingdom",
																											timeZoneIdentifier: "Europe/London",
																											latitude: 51.5072,
																											longitude: -0.1276)
	
	var url: URL? {
		switch isRealLocation {
		case true: return URL(string: "solstice://location/currentLocation")
		case false: return URL(string: "solstice://location/coordinates?lat=\(latitude)&lon=\(longitude)&timeZoneIdentifier=\(timeZoneIdentifier ?? "")&name=\(title ?? "")&subtitle=\(subtitle ?? "")")
		}
	}
}

enum SolsticeWidgetKind: String {
	case CountdownWidget, OverviewWidget, SolarChartWidget
}
