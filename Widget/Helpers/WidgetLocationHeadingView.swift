//
//  WidgetLocationHeadingView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 23/02/2023.
//

import SwiftUI
import WidgetKit

struct WidgetLocationView: View {
	var location: SolsticeWidgetLocation
	
	var locationName: String? {
		(location.isRealLocation ? location.title ?? "My Location" : location.title)
	}
	
	var body: some View {
		Group {
			if let locationName {
				if location.isRealLocation {
					Text("\(locationName) \(Image(systemName: "location"))")
				} else {
					Text(locationName)
				}
			} else {
				Label("Solstice", image: "Solstice.SFSymbol")
			}
		}
		.font(.footnote.weight(.semibold))
		.symbolVariant(.fill)
		.imageScale(.small)
	}
}

struct WidgetLocationView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			WidgetLocationView(location: SolsticeWidgetLocation(title: "London", latitude: 0, longitude: 0, isRealLocation: true))
			WidgetLocationView(location: SolsticeWidgetLocation(title: "San Francisco", latitude: 0, longitude: 0))
			WidgetLocationView(location: SolsticeWidgetLocation(latitude: 0, longitude: 0))
		}
		#if os(watchOS)
			.previewContext(WidgetPreviewContext(family: .accessoryCircular))
		#else
			.previewContext(WidgetPreviewContext(family: .systemMedium))
		#endif
	}
}
