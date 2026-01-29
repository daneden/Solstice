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
	/// Uses pre-computed Sun from timeline entry if available, otherwise computes (fallback)
	var sun: Sun? {
		if let cached = entry.cachedSun {
			return cached
		}
		// Fallback for backwards compatibility
		guard let location else { return nil }
		return Sun(for: entry.date, coordinate: location.coordinate, timeZone: location.timeZone)
	}

	/// Uses pre-computed tomorrow Sun from timeline entry if available
	var tomorrowSun: Sun? {
		entry.cachedTomorrowSun ?? sun?.tomorrow
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
