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
	@AppStorage("testNotificationsEnabled") var testNotificationsEnabled = false
	@State var settingsViewOpen = false
	
	@Environment(\.isSearching) private var isSearching
	@Environment(\.dismissSearch) private var dismissSearch
	@Environment(\.managedObjectContext) private var viewContext
	
	@State private var itemSortDimension = SortingFunction.timezone
	@State private var itemSortOrder = SortOrder.forward
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
	@State var navigationSelection: NavigationSelection?
	
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
							.tag(NavigationSelection.savedLocation(id: item.id))
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
			.navigationSplitViewColumnWidth(ideal: 256)
#if !os(watchOS)
			.searchable(text: $locationSearchService.queryFragment,
									placement: .toolbar,
									prompt: "Search cities or airports")
			.searchSuggestions {
				ForEach(locationSearchService.searchResults, id: \.hashValue) { result in
					LocationSearchResultRow(
						searchService: locationSearchService,
						navigationSelection: $navigationSelection,
						items: Array(items),
						result: result
					)
				}
			}
			.onChange(of: navigationSelection) { _ in
				locationSearchService.queryFragment = ""
				dismissSearch()
			}
#endif

			.toolbar {
				Menu {
					Picker(selection: $itemSortDimension.animation()) {
						Text("Timezone")
							.tag(SortingFunction.timezone)
						
						Text("Daylight Duration")
							.tag(SortingFunction.daylightDuration)
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
				
#if os(iOS)
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
#endif
			}
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
}

extension ContentView {
	private enum SortingFunction {
		case timezone, daylightDuration
	}
	
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
			.environmentObject(TimeMachine())
			.environmentObject(CurrentLocation())
	}
}
