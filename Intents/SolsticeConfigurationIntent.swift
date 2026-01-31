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

    @Parameter(title: "Location", default: .currentLocation)
    var locationType: LocationTypeAppEnum?

    @Parameter(title: "Choose Location")
    var location: CLPlacemark?

    static var parameterSummary: some ParameterSummary {
        Summary()
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func locationTypeParameterDisambiguationIntro(count: Int, locationType: LocationTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(locationType)’."
    }
    static func locationTypeParameterConfirmation(locationType: LocationTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(locationType)’?"
    }
    static var locationParameterPrompt: Self {
        "Which location do you want to see daylight information for?"
    }
    static func locationParameterDisambiguationIntro(count: Int, location: CLPlacemark) -> Self {
        "There are \(count) options matching ‘\(location)’."
    }
    static func locationParameterConfirmation(location: CLPlacemark) -> Self {
        "Just to confirm, you wanted ‘\(location)’?"
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum LocationTypeAppEnum: String, AppEnum {
	case currentLocation
	case customLocation
	
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Location Type")
	static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
		.currentLocation: "Use Current Location",
		.customLocation: "Choose a Location"
	]
}

