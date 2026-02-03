//
//  WidgetMissingLocationView.swift
//  Solstice
//
//  Created by Daniel Eden on 05/04/2023.
//

import SwiftUI

struct WidgetMissingLocationView: View {
	var body: some View {
		ContentUnavailableView(
			"No location found",
			systemImage: "location.slash",
			description: Text("Enable location access or edit to select a new location.")
		)
		.imageScale(.small)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// MARK: - Needs Reconfiguration View
/// Shown when a widget was configured with the old intent system and lost its custom location data during migration.
struct WidgetNeedsReconfigurationView: View {
	var body: some View {
		ContentUnavailableView(
			"Location update needed",
			image: "solstice",
			description: Text("Edit this widget to select a new location.")
		)
		.imageScale(.small)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}
