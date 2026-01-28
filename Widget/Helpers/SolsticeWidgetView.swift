//
//  SolsticeWidgetView.swift
//  Solstice
//
//  Created by Daniel Eden on 20/01/2026.
//
import SwiftUI
import SunKit

protocol SolsticeWidgetView: View {
	var entry: SolsticeWidgetTimelineEntry { get set }
}

extension SolsticeWidgetView {
	var sun: Sun? {
		guard let location else { return nil }
		return Sun(for: entry.date, coordinate: location.coordinate, timeZone: location.timeZone)
	}

	var tomorrowSun: Sun? {
		sun?.tomorrow
	}

	var relevantSun: Sun? {
		isAfterTodaySunset ? tomorrowSun : sun
	}

	var isAfterTodaySunset: Bool {
		guard let sun else { return false }
		return sun.safeSunset < entry.date
	}

	var location: SolsticeWidgetLocation? {
		entry.location
	}

	// MARK: - Error handling helpers

	/// True when we have valid data to display
	var hasValidData: Bool {
		location != nil && sun != nil
	}

	/// True when we should show a placeholder/redacted view (temporary location failure)
	var shouldShowPlaceholder: Bool {
		guard let error = entry.locationError else { return false }
		return error == .locationUpdateFailed || error == .reverseGeocodingFailed
	}
}
