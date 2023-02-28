//
//  ContentView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import CoreData

struct ContentView: View {
	@AppStorage("testNotificationsEnabled") var testNotificationsEnabled = false
	@State var settingsViewOpen = false
	
	@Environment(\.isSearching) private var isSearching
	@Environment(\.managedObjectContext) private var viewContext
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
	@State var navigationSelection: NavigationSelection? = .currentLocation
	
#if !os(watchOS)
	@StateObject var locationSearchService = LocationSearchService()
#endif
	
	@EnvironmentObject var timeMachine: TimeMachine
	@EnvironmentObject var currentLocation: CurrentLocation
	
	var body: some View {
		NavigationSplitView {
			List(selection: $navigationSelection) {
#if !os(watchOS)
				TimeMachineView()
#endif
				
				Section {
					DaylightSummaryRow(location: currentLocation)
						.tag(NavigationSelection.currentLocation)
					
					ForEach(items) { item in
						DaylightSummaryRow(location: item)
							.tag(NavigationSelection.savedLocation(id: item.id))
					}
					.onDelete(perform: deleteItems)
				} header: {
					Label("Locations", systemImage: "map")
				}
			}
			.navigationTitle("Solstice")
			.navigationSplitViewColumnWidth(ideal: 256)
#if !os(watchOS)
			.searchable(text: $locationSearchService.queryFragment,
									placement: .toolbar,
									prompt: "Search cities or airports")
			.searchSuggestions {
				ForEach(locationSearchService.searchResults, id: \.hashValue) { result in
					LocationSearchResultRow(
						searchService: locationSearchService,
						navigationSelection: $navigationSelection, result: result
					)
				}
			}
#endif
#if os(iOS)
			.toolbar {
				Button {
					settingsViewOpen.toggle()
				} label: {
					Label("Settings", systemImage: "gearshape")
				}
				.sheet(isPresented: $settingsViewOpen) {
					NavigationStack {
						SettingsView()
					}
				}
			}
#endif
		} detail: {
			switch navigationSelection {
			case .currentLocation:
				DetailView(
					navigationSelection: $navigationSelection,
					location: currentLocation
				)
			case .savedLocation(let id):
				if let item = items.first(where: { $0.id == id }) {
					DetailView(
						navigationSelection: $navigationSelection,
						location: item
					)
				} else {
					placeholderView
				}
			case .temporaryLocation(let location):
				DetailView(
					navigationSelection: $navigationSelection,
					location: location
				)
			case .none:
				placeholderView
			}
		}
	}
	
	private var placeholderView: some View {
		Image("Solstice-Icon")
			.resizable()
			.foregroundStyle(.quaternary)
			.frame(width: 100, height: 100)
			.aspectRatio(contentMode: .fit)
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

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	}
}
