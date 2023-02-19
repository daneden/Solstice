//
//  ContentView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import CoreData

enum NavigationSelection: Hashable {
	case currentLocation
	case savedLocation(id: SavedLocation.ID)
}

struct ContentView: View {
	@Environment(\.isSearching) private var isSearching
	@Environment(\.managedObjectContext) private var viewContext
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
	@State var navigationSelection: NavigationSelection? = .currentLocation
	@StateObject var locationSearchService = LocationSearchService()
	@StateObject var currentLocation = CurrentLocation()
	
	@EnvironmentObject var timeMachine: TimeMachine
	
	var body: some View {
		NavigationView {
			List(selection: $navigationSelection) {
				TimeMachineView()
				
				Section {
					NavigationLink {
						DetailView(location: currentLocation)
					} label: {
						DaylightSummaryRow(location: currentLocation)
					}
					.tag(NavigationSelection.currentLocation)
					
					ForEach(items) { item in
						NavigationLink {
							DetailView(location: item)
						} label: {
							DaylightSummaryRow(location: item)
						}
						.tag(NavigationSelection.savedLocation(id: item.id))
					}
					.onDelete(perform: deleteItems)
				} header: {
					Label("Locations", systemImage: "map")
				}
			}
			.navigationTitle("Solstice")
			
			Image("Solstice-Icon")
				.resizable()
				.foregroundStyle(.quaternary)
				.frame(width: 100, height: 100)
				.aspectRatio(contentMode: .fit)
		}
		.searchable(text: $locationSearchService.queryFragment,
								placement: .toolbar,
								prompt: "Search cities or airports")
		.searchSuggestions {
			ForEach(locationSearchService.searchResults, id: \.hashValue) { result in
				LocationSearchResultRow(searchService: locationSearchService, result: result)
			}
		}
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			offsets.map { items[$0] }.forEach(viewContext.delete)
			
			do {
				try viewContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nsError = error as NSError
				fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
	}
}

private let itemFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateStyle = .short
	formatter.timeStyle = .medium
	return formatter
}()

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	}
}
