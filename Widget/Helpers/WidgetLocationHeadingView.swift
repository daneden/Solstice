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
	
	var locationName: Text {
		guard let title = location.title else {
			switch location.isRealLocation {
			case true:
				return Text("My Location \(Image(systemName: "location"))")
			case false:
				return Text("\(Image("Solstice.SFSymbol")) Solstice")
			}
		}
		
		return Text(title)
	}
	
	var body: some View {
		locationName
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
