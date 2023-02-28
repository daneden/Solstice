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
	
	@ObservedObject var searchService: LocationSearchService
	@Binding var navigationSelection: NavigationSelection?
	
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
					.controlSize(.small)
			}
		}
		.contentShape(Rectangle())
		.onTapGesture {
			Task {
				guard let temporaryLocation = try? await buildTemporaryLocation(from: result) else { return }
				navigationSelection = .temporaryLocation(temporaryLocation)
			}
		}
	}
	
	func buildTemporaryLocation(from completion: MKLocalSearchCompletion) async throws -> TemporaryLocation? {
		isAddingItem = true
		let searchRequest = MKLocalSearch.Request(completion: completion)
		let searchResult = try await MKLocalSearch(request: searchRequest).start()
		if let item = searchResult.mapItems.first {
			let coords = item.placemark.coordinate

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
