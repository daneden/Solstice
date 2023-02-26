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
				await addLocation(from: result)
				dismiss()
			}
		}
		.disabled(isAddingItem)
	}
	
	func addLocation(from completion: MKLocalSearchCompletion) async {
		isAddingItem = true
		let searchRequest = MKLocalSearch.Request(completion: completion)
		
		do {
			let searchResult = try await MKLocalSearch(request: searchRequest).start()
			if let item = searchResult.mapItems.first {
				let coords = item.placemark.coordinate
				let newLocation = SavedLocation(context: viewContext)
				let reverseGeocoding = try await CLGeocoder().reverseGeocodeLocation(item.placemark.location!)
				
				newLocation.title = completion.title
				newLocation.subtitle = completion.subtitle
				newLocation.timeZoneIdentifier = item.placemark.timeZone?.identifier ?? reverseGeocoding.first?.timeZone?.identifier
				newLocation.latitude = coords.latitude
				newLocation.longitude = coords.longitude
				
				try viewContext.save()
				searchService.queryFragment = ""
			}
		} catch {
			print(error)
		}

		isAddingItem = false
	}
}

//struct AddLocationView_Previews: PreviewProvider {
//    static var previews: some View {
//        LocationSearchResultRow()
//    }
//}
