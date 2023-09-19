//
//  WidgetMissingLocationView.swift
//  Solstice
//
//  Created by Daniel Eden on 05/04/2023.
//

import SwiftUI

struct WidgetMissingLocationView: View {
	@Environment(\.widgetFamily) var family
	
	var locationMissingIcon = Image("location.slash")
	
	var body: some View {
		switch family {
#if !os(macOS)
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
