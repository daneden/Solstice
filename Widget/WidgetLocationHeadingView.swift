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
	
	var body: some View {
		if let locationName = location.title {
			Group {
				if location.isRealLocation {
					Text("\(locationName) \(Image(systemName: "location"))")
				} else {
					Text(locationName)
				}
			}
			.font(.footnote.weight(.semibold))
			.symbolVariant(.fill)
			.imageScale(.small)
		}
	}
}

struct WidgetLocationView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			WidgetLocationView(location: SolsticeWidgetLocation(title: "London", latitude: 0, longitude: 0, isRealLocation: true))
			WidgetLocationView(location: SolsticeWidgetLocation(title: "San Francisco", latitude: 0, longitude: 0))
		}
			.previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}