//
//  SolsticeWidgetConfiguration.swift
//  Widget
//
//  Created by Daniel Eden on 30/01/2026.
//

import AppIntents
import WidgetKit
import CoreLocation

// MARK: - Location Type Enum

enum WidgetLocationType: String, AppEnum {
	case currentLocation
	case customLocation

	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Location Type")

	static var caseDisplayRepresentations: [WidgetLocationType: DisplayRepresentation] = [
		.currentLocation: DisplayRepresentation(title: "Current Location"),
		.customLocation: DisplayRepresentation(title: "Custom Location")
	]
}

// MARK: - Widget Configuration Intent

struct SolsticeWidgetConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource = "Configure Widget"
	static var description = IntentDescription("Choose the location for the widget")

	@Parameter(title: "Location Type", default: .currentLocation)
	var locationType: WidgetLocationType

	@Parameter(title: "Location")
	var customLocation: CLPlacemark?

	static var parameterSummary: some ParameterSummary {
		When(\.$locationType, .equalTo, .customLocation) {
			Summary {
				\.$locationType
				\.$customLocation
			}
		} otherwise: {
			Summary {
				\.$locationType
			}
		}
	}

	init() {}

	init(locationType: WidgetLocationType, customLocation: CLPlacemark? = nil) {
		self.locationType = locationType
		self.customLocation = customLocation
	}
}

// MARK: - CLPlacemark to SolsticeWidgetLocation conversion

extension CLPlacemark {
	var widgetLocation: SolsticeWidgetLocation? {
		guard let location = self.location else { return nil }

		return SolsticeWidgetLocation(
			title: locality ?? name,
			subtitle: country,
			timeZoneIdentifier: timeZone?.identifier,
			latitude: location.coordinate.latitude,
			longitude: location.coordinate.longitude,
			isRealLocation: false
		)
	}
}
