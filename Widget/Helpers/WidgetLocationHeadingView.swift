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

	/// Current location is already geocoded live into `title`; only saved/custom
	/// locations benefit from the per-locale cache populated by the app.
	private var displayTitle: String? {
		guard !location.isRealLocation else { return location.title }
		let cached = LocalizedNameCache.read(key: LocalizedNameCache.key(latitude: location.latitude, longitude: location.longitude))
		return cached?.title ?? location.title
	}

	var locationName: Text {
		guard let title = displayTitle else {
			switch location.isRealLocation {
			case true:
				return Text("Current Location \(Image(systemName: "location"))")
			case false:
				return Text("\(Image(.solstice)) Solstice")
			}
		}

		switch location.isRealLocation {
		case true:
			return Text("\(Text(title)) \(Image(systemName: "location"))", comment: "Widget heading for real location")
		case false:
			return Text("\(Image(.solstice)) \(Text(title))", comment: "Widget heading for custom location")
		}
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
