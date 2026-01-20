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
}
