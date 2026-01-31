//
//  Configuration.swift
//  Solstice
//
//  Created by Daniel Eden on 31/01/2026.
//

import Foundation
import AppIntents
import CoreLocation

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct SolsticeConfigurationIntent: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
	static let intentClassName = "ConfigurationIntent"

	static var title: LocalizedStringResource = "Configuration"
	static var description = IntentDescription("The configuration options for Solstice widgets")

	/// The selected location for the widget. Uses current location when nil.
	@Parameter(title: "Location")
	var location: LocationAppEntity?

	/// Resolved location - returns the selected location or current location as default
	var resolvedLocation: LocationAppEntity {
		location ?? .currentLocation
	}

	static var parameterSummary: some ParameterSummary {
		Summary("Show daylight for \(\.$location)")
	}

	init() {}

	init(location: LocationAppEntity?) {
		self.location = location
	}

	func perform() async throws -> some IntentResult {
		return .result()
	}

	// MARK: - Migration from old ConfigurationIntent

	/// Migrates from the old ConfigurationIntent which used LocationTypeAppEnum and CLPlacemark
	static func migrateConfiguration(
		locationType: LocationTypeAppEnum_Legacy?,
		placemark: CLPlacemark?
	) -> SolsticeConfigurationIntent {
		var intent = SolsticeConfigurationIntent()

		switch locationType {
		case .currentLocation, .none:
			// Current location - use nil (will resolve to current location)
			intent.location = nil

		case .customLocation:
			// Custom location - try to migrate the placemark
			if let placemark,
			   let coordinate = placemark.location?.coordinate {
				intent.location = LocationAppEntity(
					id: "migrated:\(coordinate.latitude),\(coordinate.longitude)",
					title: placemark.locality ?? placemark.name ?? "Custom Location",
					subtitle: placemark.country,
					latitude: coordinate.latitude,
					longitude: coordinate.longitude,
					timeZoneIdentifier: placemark.timeZone?.identifier,
					savedLocationUUID: nil
				)
			}
			// If migration fails, location stays nil (current location)
		}

		return intent
	}
}

// MARK: - Legacy Types for Migration

/// Legacy enum used in the old ConfigurationIntent
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum LocationTypeAppEnum_Legacy: String, AppEnum {
	case currentLocation
	case customLocation

	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Location Type")
	static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
		.currentLocation: "Use Current Location",
		.customLocation: "Choose a Location"
	]
}

// MARK: - Intent Dialogs

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
	static var locationParameterPrompt: Self {
		"Which location do you want to see daylight information for?"
	}
	static func locationParameterDisambiguationIntro(count: Int, location: LocationAppEntity) -> Self {
		"There are \(count) options matching '\(location.title)'."
	}
	static func locationParameterConfirmation(location: LocationAppEntity) -> Self {
		"Just to confirm, you wanted '\(location.title)'?"
	}
}
