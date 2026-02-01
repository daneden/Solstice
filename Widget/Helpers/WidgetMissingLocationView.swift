//
//  WidgetMissingLocationView.swift
//  Solstice
//
//  Created by Daniel Eden on 05/04/2023.
//

import SwiftUI

struct WidgetMissingLocationView: View {
	@Environment(\.widgetFamily) var family
	
	var locationMissingIcon = Image(systemName: "location.slash")
	
	var body: some View {
		switch family {
#if os(watchOS) || os(iOS)
		case .accessoryCorner:
			locationMissingIcon
				.widgetLabel {
					Text("Location required")
				}
		case .accessoryCircular:
			locationMissingIcon
				.widgetLabel {
					Text("Location required")
				}
		case .accessoryInline:
			Label("Location required", systemImage: "location.slash")
#endif
		default:
			VStack(alignment: .leading) {
				Text("\(locationMissingIcon) Location required")
					.font(.headline)
				Text("Enable location services for Solstice, or choose a location by configuring the widget")
					.foregroundStyle(.secondary)
			}
		}
	}
}

struct WidgetMissingLocationView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetMissingLocationView()
    }
}

// MARK: - Needs Reconfiguration View

/// Shown when a widget was configured with the old intent system and lost its custom location data during migration.
struct WidgetNeedsReconfigurationView: View {
	@Environment(\.widgetFamily) var family

	private let reconfigureIcon = Image(systemName: "arrow.triangle.2.circlepath")

	var body: some View {
		switch family {
#if os(watchOS) || os(iOS)
		case .accessoryCorner:
			reconfigureIcon
				.widgetLabel {
					Text("Tap to update")
				}
		case .accessoryCircular:
			reconfigureIcon
				.widgetLabel {
					Text("Tap to update")
				}
		case .accessoryInline:
			Label("Tap to update location", systemImage: "arrow.triangle.2.circlepath")
#endif
		default:
			VStack(alignment: .leading) {
				Text("\(reconfigureIcon) Location update needed")
					.font(.headline)
				Text("This widget's location was reset during an app update. Tap to reconfigure.")
					.foregroundStyle(.secondary)
			}
		}
	}
}
