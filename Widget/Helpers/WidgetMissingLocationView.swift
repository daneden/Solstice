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
		switch family {
		#if !os(macOS)
		case .accessoryCorner:
			Image("location.slash")
				.widgetLabel {
					Text("Location Required")
				}
		case .accessoryCircular:
			Image("location.slash")
				.widgetLabel {
					Text("Location Required")
				}
		case .accessoryInline:
			Label("Location Required", systemImage: "location.slash")
		#endif
		default:
			VStack {
				Text("Location Required")
					.font(.headline)
				Text("Enable location services for Solstice, or choose a location by configuring the widget")
			}
		}
	}
}

struct WidgetMissingLocationView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetMissingLocationView()
    }
}
