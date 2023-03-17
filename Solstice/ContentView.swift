//
//  ContentView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import CoreData
import Solar

struct ContentView: View {
	@SceneStorage("navigationState") private var navigationStateData: Data?
	@State var settingsViewOpen = false
	@StateObject private var navigationState = NavigationStateManager()

	@Environment(\.isSearching) private var isSearching
	@Environment(\.dismissSearch) private var dismissSearch
	@Environment(\.managedObjectContext) private var viewContext
	
	@AppStorage(Preferences.listViewOrderBy) private var itemSortDimension
	@AppStorage(Preferences.listViewSortOrder) private var itemSortOrder
	@AppStorage(Preferences.listViewShowComplication) private var showComplication
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
#if !os(watchOS)
	@StateObject var locationSearchService = LocationSearchService()
#endif
	
	@ObservedObject var timeMachine =  TimeMachine.shared
	@EnvironmentObject var currentLocation: CurrentLocation
	
	var body: some View {
		NavigationSplitView {
			List(selection: $navigationState.navigationSelection) {
				if timeMachine.isOn {
					TimeMachineDeactivatorView()
				}
				
				if CurrentLocation.authorizationStatus == .notDetermined {
					LocationPermissionScreenerView()
				}
				
				Section {
					if !CurrentLocation.isAuthorized && items.isEmpty {
						VStack {
							Text("No locations")
								.font(.headline)
							Text("Search for a location or enable location services")
						}
						.frame(maxWidth: .infinity)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
					}
					
					if CurrentLocation.isAuthorized {
						DaylightSummaryRow(location: currentLocation)
							.tag(NavigationSelection.currentLocation)
					}
					
					ForEach(sortedItems) { item in
						DaylightSummaryRow(location: item)
							.tag(NavigationSelection.savedLocation(id: item.uuid))
							.contextMenu {
								Button(role: .destructive) {
									deleteItem(item)
								} label: {
									Label("Delete Location", systemImage: "trash")
								}
							}
					}
					.onDelete(perform: deleteItems)
				} header: {
					Label("Locations", systemImage: "map")
				}
			}
			.navigationTitle("Solstice")
			.navigationSplitViewColumnWidth(ideal: 300)
#if !os(watchOS)
			.searchable(text: $locationSearchService.queryFragment,
									prompt: "Search cities or airports")
			.searchSuggestions {
				ForEach(locationSearchService.searchResults, id: \.hashValue) { result in
					LocationSearchResultRow(
						searchService: locationSearchService,
						items: Array(items),
						result: result
					)
				}
			}
#endif
			.toolbar {
				toolbarItems
			}
		} detail: {
			switch navigationState.navigationSelection {
			case .currentLocation:
				DetailView(location: currentLocation)
			case .savedLocation(let id):
				if let item = items.first(where: { $0.uuid == id }) {
					DetailView(location: item)
				} else {
					placeholderView
				}
			case .none:
				placeholderView
			}
		}
		.sheet(item: $navigationState.temporaryLocation) { value in
			if let value {
				NavigationStack {
					DetailView(location: value)
				}
				#if os(macOS)
				.frame(minWidth: 600, minHeight: 400)
				#endif
			}
		}
		.environmentObject(navigationState)
		.task(priority: TaskPriority.background) {
			items.forEach { item in
				if item.uuid == nil {
					item.uuid = UUID()
				}
			}
			
			do {
				try viewContext.save()
			} catch {
				print(error)
			}
		}
		.task {
			if let navigationStateData {
				navigationState.jsonData = navigationStateData
			}
			
			for await _ in navigationState.objectWillChangeSequence {
				navigationStateData = navigationState.jsonData
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
			offsets.map { sortedItems[$0] }.forEach(viewContext.delete)
			
			do {
				try viewContext.save()
			} catch {
				print(error)
			}
		}
	}
	
	private func deleteItem(_ item: SavedLocation) {
		withAnimation {
			viewContext.delete(item)
			
			do {
				try viewContext.save()
			} catch {
				print(error)
			}
		}
	}
	
	@ToolbarContentBuilder
	private var toolbarItems: some ToolbarContent {
		ToolbarItem {
			Menu {
				Menu {
					Picker(selection: $itemSortDimension.animation()) {
						Text("Timezone")
							.tag(Preferences.SortingFunction.timezone)
						
						Text("Daylight Duration")
							.tag(Preferences.SortingFunction.daylightDuration)
					} label: {
						Text("Sort by")
					}
					
					Picker(selection: $itemSortOrder.animation()) {
						Text("Ascending")
							.tag(SortOrder.forward)
						
						Text("Descending")
							.tag(SortOrder.reverse)
					} label: {
						Text("Order")
					}
				} label: {
					Label("Sort locations", systemImage: "arrow.up.arrow.down.circle")
				}
				
				Toggle(isOn: $showComplication.animation()) {
					Text("Show chart in list")
				}
			} label: {
				Label("View Options", systemImage: "eye.circle")
			}
		}
		
#if os(iOS)
		ToolbarItem {
			Button {
				settingsViewOpen.toggle()
			} label: {
				Label("Settings", systemImage: "gearshape")
			}
			.sheet(isPresented: $settingsViewOpen) {
				SettingsView()
			}
		}
#endif
	}
}

extension ContentView {
	private var sortedItems: [SavedLocation] {
		items.sorted { lhs, rhs in
			switch itemSortDimension {
			case .timezone:
				switch itemSortOrder {
				case .forward:
					return lhs.timeZone.secondsFromGMT() < rhs.timeZone.secondsFromGMT()
				case .reverse:
					return lhs.timeZone.secondsFromGMT() > rhs.timeZone.secondsFromGMT()
				}
			case .daylightDuration:
				guard let lhsSolar = Solar(for: timeMachine.date, coordinate: lhs.coordinate.coordinate),
							let rhsSolar = Solar(for: timeMachine.date, coordinate: rhs.coordinate.coordinate) else {
					return true
				}
				
				switch itemSortOrder {
				case .forward:
					return lhsSolar.daylightDuration < rhsSolar.daylightDuration
				case .reverse:
					return lhsSolar.daylightDuration > rhsSolar.daylightDuration
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
			.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
			.environmentObject(TimeMachine.preview)
			.environmentObject(CurrentLocation())
	}
}
