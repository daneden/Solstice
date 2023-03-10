//
//  AddLocationView.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import SwiftUI
import MapKit

struct LocationSearchResultRow: View {
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.dismissSearch) private var dismiss
	
	@EnvironmentObject var navigationState: NavigationStateManager
	@ObservedObject var searchService: LocationSearchService
	
	var items: Array<SavedLocation> = []
	
	@State private var isAddingItem = false

	var result: MKLocalSearchCompletion
	
	var body: some View {
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
				#if !os(tvOS)
					.controlSize(.small)
				#endif
			}
		}
		.contentShape(Rectangle())
		.onTapGesture {
			Task {
				guard let location = try? await getLocation(from: result) else { return }
				
				if let location = location as? TemporaryLocation {
					navigationState.temporaryLocation = location
				} else if let locationId = (location as? SavedLocation)?.uuid {
					navigationState.navigationSelection = .savedLocation(id: locationId)
				}
			}
		}
	}
	
	func getLocation(from completion: MKLocalSearchCompletion) async throws -> (any ObservableLocation)? {
		isAddingItem = true
		let searchRequest = MKLocalSearch.Request(completion: completion)
		let searchResult = try await MKLocalSearch(request: searchRequest).start()
		if let item = searchResult.mapItems.first {
			let coords = item.placemark.coordinate
			
			if let location = item.placemark.location,
				 let savedLocation = items.first(where: { savedLocation in
					 savedLocation.coordinate.distance(from: location) < 1000
				 }) {
				return savedLocation
			}

			let reverseGeocoding = try await CLGeocoder().reverseGeocodeLocation(item.placemark.location!)
			searchService.queryFragment = ""
			isAddingItem = false
			
			return TemporaryLocation(
				title: completion.title,
				subtitle: completion.subtitle,
				timeZoneIdentifier: item.placemark.timeZone?.identifier ?? reverseGeocoding.first?.timeZone?.identifier,
				latitude: coords.latitude,
				longitude: coords.longitude
			)
		} else {
			return nil
		}
	}
}

//struct AddLocationView_Previews: PreviewProvider {
//    static var previews: some View {
//        LocationSearchResultRow()
//    }
//}
