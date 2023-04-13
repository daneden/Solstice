//
//  SidebarListView.swift
//  Solstice
//
//  Created by Daniel Eden on 19/03/2023.
//

import SwiftUI
import Solar

struct SidebarListView: View {
	@EnvironmentObject var currentLocation: CurrentLocation
	@EnvironmentObject var timeMachine: TimeMachine
	@EnvironmentObject var locationSearchService: LocationSearchService
	
	@Environment(\.managedObjectContext) private var viewContext
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
		
	@SceneStorage("selectedLocation") private var selectedLocation: NavigationSelection?
	
	@AppStorage(Preferences.listViewOrderBy) private var itemSortDimension
	@AppStorage(Preferences.listViewSortOrder) private var itemSortOrder
	@AppStorage(Preferences.listViewShowComplication) private var showComplication
	
	var body: some View {
		List(selection: $selectedLocation) {
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
					#if os(iOS)
						.onDrag {
							let userActivity = NSUserActivity(activityType: DetailView<CurrentLocation>.userActivity)
							
							userActivity.title = "See daylight for current location"
							userActivity.targetContentIdentifier = currentLocation.id
							
							return NSItemProvider(object: userActivity)
						}
					#endif
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
						} preview: {
							DetailView(location: item)
								.environmentObject(timeMachine)
						}
					#if os(iOS)
						.onDrag {
							let userActivity = NSUserActivity(activityType: DetailView<SavedLocation>.userActivity)
							
							userActivity.title = "See daylight for \(item.title!)"
							userActivity.targetContentIdentifier = item.uuid?.uuidString
							
							return NSItemProvider(object: userActivity)
						}
					#endif
						.id(item.id)
				}
				.onDelete(perform: deleteItems)
				.id(timeMachine.date)
			} header: {
				Label("Locations", systemImage: "map")
			}
		}
		.navigationTitle("Solstice")
		.navigationSplitViewColumnWidth(ideal: 300)
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
	}
}

extension SidebarListView {
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
				guard let lhsSolar = Solar(for: timeMachine.date, coordinate: lhs.coordinate),
							let rhsSolar = Solar(for: timeMachine.date, coordinate: rhs.coordinate) else {
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

struct SidebarListView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			SidebarListView()
		}
			.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
			.environmentObject(TimeMachine.preview)
			.environmentObject(CurrentLocation())
	}
}
