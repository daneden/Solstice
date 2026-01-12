//
//  DeepLinkResolver.swift
//  Solstice
//
//  Created by Daniel Eden on 28/06/2024.
//

import SwiftUI
import CoreLocation

struct DeepLinkResolver: ViewModifier {
	@SceneStorage("selectedLocation") var selectedLocation: String?
	@Environment(LocationSearchService.self) var searchService
	var items: [SavedLocation] = []
	
	func body(content: Content) -> some View {
		content
			.onOpenURL { url in
				guard let host = url.host(), host == "location" else {
					return
				}
				
				switch url.lastPathComponent {
				case CurrentLocation.identifier: withAnimation { selectedLocation = CurrentLocation.identifier }
				case "coordinates":
					guard let queryItems = URLComponents(string: url.absoluteString)?.queryItems,
								let lat = queryItems.first(where: { $0.name == "lat" })?.value,
								let lon = queryItems.first(where: { $0.name == "lon" })?.value,
								let latitude = Double(lat),
								let longitude = Double(lon) else {
						return
					}

					let closestLocation = items.first(where: { item in
						let location = CLLocation(latitude: item.latitude, longitude: item.longitude)
						return location.distance(from: CLLocation(latitude: latitude, longitude: longitude)) <= 10000
					})
					
					if let closestLocation {
						withAnimation {
							selectedLocation = closestLocation.uuid?.uuidString
						}
					} else {
						guard let name = queryItems.first(where: { $0.name == "name" })?.value,
									let subtitle = queryItems.first(where: { $0.name == "subtitle" })?.value,
									let timeZoneIdentifier = queryItems.first(where: { $0.name == "timeZoneIdentifier" })?.value else {
							return
						}
						
						let location = TemporaryLocation(title: name,
																						 subtitle: subtitle,
																						 timeZoneIdentifier: timeZoneIdentifier,
																						 latitude: latitude,
																						 longitude: longitude)
						
						searchService.location = location
					}
				default: return
				}
			}
	}
}

extension View {
	func resolveDeepLink(_ locations: [SavedLocation] = []) -> some View {
		return self.modifier(DeepLinkResolver(items: locations))
	}
}
