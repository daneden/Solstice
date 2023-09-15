//
//  WidgetMissingLocationView.swift
//  Solstice
//
//  Created by Daniel Eden on 05/04/2023.
//

import SwiftUI

struct WidgetMissingLocationView: View {
	@Environment(\.widgetFamily) var family
	
	var body: some View {
		Group {
			switch family {
#if !os(macOS)
			case .accessoryCorner:
				Image("location.slash")
			case .accessoryCircular:
				Image("location.slash")
			case .accessoryInline:
				Label("Location required", systemImage: "location.slash")
#endif
			default:
				VStack {
					Text("Location required")
						.font(.headline)
					Text("Enable location services for Solstice, or choose a location by configuring the widget")
				}
			}
		}
		.widgetLabel {
			Text("Location required")
		}
	}
}

struct WidgetMissingLocationView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetMissingLocationView()
    }
}
