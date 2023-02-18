//
//  AddLocationView.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import SwiftUI
import MapKit


struct AddLocationView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.dismiss) private var dismiss
	@StateObject var searchService = LocationSearchService()
	private let searchRequest = MKLocalSearch.Request()
	
	var body: some View {
		Form {
			ZStack(alignment: .trailing) {
				TextField("Search for a location", text: $searchService.queryFragment)
				Button {
					searchService.queryFragment = ""
				} label: {
					Label("Clear", systemImage: "xmark.circle.fill")
				}
				.labelStyle(.iconOnly)
				.foregroundStyle(.tertiary)
				.opacity(searchService.queryFragment.isEmpty ? 0 : 1)
			}
			
			ForEach(searchService.searchResults.filter { !$0.subtitle.isEmpty }, id: \.hashValue) { result in
				VStack(alignment: .leading) {
					Text(result.title)
					Text(result.subtitle)
						.foregroundStyle(.secondary)
						.font(.footnote)
				}.onTapGesture {
					Task {
						await addLocation(from: result)
						dismiss()
					}
				}
			}
		}
		.navigationTitle("Add Location")
		.toolbar {
			Button {
				dismiss()
			} label: {
				Text("Cancel")
			}
		}
	}
	
	func addLocation(from completion: MKLocalSearchCompletion) async {
		searchRequest.naturalLanguageQuery = "\(completion.title), \(completion.subtitle)"
		
		do {
			let searchResult = try await MKLocalSearch(request: searchRequest).start()
			if let item = searchResult.mapItems.first {
				let coords = item.placemark.coordinate
				let newLocation = SavedLocation(context: viewContext)
				let reverseGeocoding = try await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coords.latitude, longitude: coords.longitude))
				
				newLocation.title = completion.title
				newLocation.subtitle = completion.subtitle
				newLocation.timeZoneIdentifier = item.placemark.timeZone?.identifier ?? reverseGeocoding.first?.timeZone?.identifier
				newLocation.latitude = coords.latitude
				newLocation.longitude = coords.longitude
				
				try viewContext.save()
			}
		} catch {
			print(error)
		}
	}
}

struct AddLocationView_Previews: PreviewProvider {
    static var previews: some View {
        AddLocationView()
    }
}
