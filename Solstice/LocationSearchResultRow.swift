//
//  LocationSearchResultRow.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import CoreData
import MapKit
import SwiftUI

struct LocationSearchResultRow: View {
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.dismissSearch) private var dismiss

	@SceneStorage("selectedLocation") private var selectedLocation: String?
	var searchService: LocationSearchService

	var items: [SavedLocation] = []

	@State private var isAddingItem = false

	var result: MKLocalSearchCompletion

	var body: some View {
		Button {
			Task {
				guard let location = try? await getLocation(from: result) else { return }

				if let location = location as? TemporaryLocation {
					searchService.location = location
				} else if let locationId = (location as? SavedLocation)?.uuid {
					selectedLocation = locationId.uuidString
				}
			}
		} label: {
			HStack {
				VStack(alignment: .leading) {
					Text(result.title)
					if !result.subtitle.isEmpty {
						Text(result.subtitle)
							.foregroundStyle(.secondary)
							.font(.footnote)
					}
				}

				Spacer()

				if isAddingItem {
					ProgressView()
						.controlSize(.small)
				}
			}
		}
		.contentShape(Rectangle())
		.foregroundStyle(.primary)
	}

	func getLocation(from completion: MKLocalSearchCompletion) async throws -> (any ObservableLocation)? {
		isAddingItem = true
		let searchRequest = MKLocalSearch.Request(completion: completion)
		let searchResult = try await MKLocalSearch(request: searchRequest).start()
		if let item = searchResult.mapItems.first {
			#if os(visionOS)
				let location = item.location
				let country = item.addressRepresentations?.regionName
				let itemTimeZone = item.timeZone
			#else
				guard let location = item.placemark.location else {
					return nil
				}
				let country = item.placemark.country
				let itemTimeZone = item.placemark.timeZone
			#endif
			let coords = location.coordinate

			if let savedLocation = items.first(where: { savedLocation in
				// Avoid duplicate items by filtering locations less than 5km from the specified location
				CLLocation(
					latitude: savedLocation.coordinate.latitude,
					longitude: savedLocation.coordinate.longitude
				).distance(from: location) < 5000
			}) {
				return savedLocation
			}

			let timeZoneIdentifier: String?
			if let itemTimeZone {
				timeZoneIdentifier = itemTimeZone.identifier
			} else {
				timeZoneIdentifier = await ReverseGeocoder.reverseGeocode(location)?.timeZone?.identifier
			}
			searchService.queryFragment = ""
			isAddingItem = false

			return TemporaryLocation(
				title: completion.title,
				subtitle: completion.subtitle.isEmpty ? country : completion.subtitle,
				timeZoneIdentifier: timeZoneIdentifier,
				latitude: coords.latitude,
				longitude: coords.longitude
			)
		} else {
			return nil
		}
	}
}
