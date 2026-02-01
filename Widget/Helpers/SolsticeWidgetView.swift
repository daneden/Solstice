//
//  SolsticeWidgetView.swift
//  Solstice
//
//  Created by Daniel Eden on 20/01/2026.
//
import SwiftUI
import Solar

protocol SolsticeWidgetView: View {
	var entry: SolsticeWidgetTimelineEntry { get set }
}

extension SolsticeWidgetView {
	var solar: Solar? {
		guard let location else { return nil }
		return Solar(for: entry.date, coordinate: location.coordinate)
	}

	var tomorrowSolar: Solar? {
		solar?.tomorrow
	}

	var relevantSolar: Solar? {
		isAfterTodaySunset ? tomorrowSolar : solar
	}

	var isAfterTodaySunset: Bool {
		guard let solar else { return false }
		return solar.safeSunset < entry.date
	}

	var location: SolsticeWidgetLocation? {
		entry.location
	}

	// MARK: - Error handling helpers

	/// True when we have valid data to display
	var hasValidData: Bool {
		location != nil && solar != nil
	}

	/// True when we should show a placeholder/redacted view (temporary location failure)
	var shouldShowPlaceholder: Bool {
		guard let error = entry.locationError else { return false }
		return error == .locationUpdateFailed || error == .reverseGeocodingFailed
	}

	/// True when the widget needs reconfiguration due to lost location data from migration
	var needsReconfiguration: Bool {
		entry.locationError == .needsReconfiguration
	}
}
