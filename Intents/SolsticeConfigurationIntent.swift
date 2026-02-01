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

	// MARK: - New Parameter (for fresh configurations)

	/// The selected location for the widget using the new entity type
	@Parameter(title: "Location")
	var selectedLocation: LocationAppEntity?

	// MARK: - Legacy Parameters (for migration from old ConfigurationIntent)
	// These match the old ConfigurationIntent parameter names and types exactly
	// so the system can automatically migrate existing widget configurations.

	/// Legacy: The location type from old ConfigurationIntent
	/// Matches old parameter: `locationType: LocationType`
	@Parameter(title: "Location Type")
	var locationType: LocationTypeAppEnum?

	/// Legacy: The custom location placemark from old ConfigurationIntent
	/// Matches old parameter: `location: CLPlacemark?`
	@Parameter(title: "Custom Location")
	var location: CLPlacemark?

	// MARK: - Resolved Location

	/// Returns the effective location by checking new parameter first, then legacy parameters
	var resolvedLocation: LocationAppEntity {
		// First, check if new selectedLocation is set
		if let selectedLocation {
			return selectedLocation
		}

		// Fall back to legacy parameters for migrated widgets
		switch locationType {
		case .customLocation:
			// Custom location - convert CLPlacemark to LocationAppEntity
			if let placemark = location,
			   let coordinate = placemark.location?.coordinate {
				return LocationAppEntity(
					id: "migrated:\(coordinate.latitude),\(coordinate.longitude)",
					title: placemark.locality ?? placemark.name ?? "Custom Location",
					subtitle: placemark.country,
					latitude: coordinate.latitude,
					longitude: coordinate.longitude,
					timeZoneIdentifier: placemark.timeZone?.identifier,
					savedLocationUUID: nil
				)
			}
			// Fall through to current location if placemark is invalid
			fallthrough

		case .currentLocation, .unknown, .none:
			return .currentLocation
		}
	}

	/// Whether this configuration needs timezone lookup (legacy migrations may not have timezone)
	var needsTimezoneResolution: Bool {
		if selectedLocation != nil {
			return false // New selections already have timezone
		}
		// Legacy custom locations need timezone lookup
		return locationType == .customLocation && location?.timeZone == nil
	}

	static var parameterSummary: some ParameterSummary {
		Summary("Show daylight for \(\.$selectedLocation)")
	}

	init() {}

	init(selectedLocation: LocationAppEntity?) {
		self.selectedLocation = selectedLocation
	}

	func perform() async throws -> some IntentResult {
		return .result()
	}
}

// MARK: - Legacy Enum for Migration

/// Matches the old LocationType enum from ConfigurationIntent
/// Raw values must match for proper migration:
/// - unknown = 0, currentLocation = 1, customLocation = 2
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum LocationTypeAppEnum: Int, AppEnum {
	case unknown = 0
	case currentLocation = 1
	case customLocation = 2

	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Location Type")
	static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
		.unknown: "Unknown",
		.currentLocation: "Current Location",
		.customLocation: "Custom Location"
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
