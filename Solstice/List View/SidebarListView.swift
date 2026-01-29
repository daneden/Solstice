//
//  SidebarListView.swift
//  Solstice
//
//  Created by Daniel Eden on 19/03/2023.
//

import SwiftUI
import Solar
import TimeMachine

struct SidebarListView: View {
	@AppStorage(Preferences.listViewAppearance) private var appearance
	@Environment(CurrentLocation.self) var currentLocation
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	@Environment(LocationSearchService.self) var locationSearchService
	
	@Environment(\.managedObjectContext) private var viewContext
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
		
	@SceneStorage("selectedLocation") private var selectedLocation: String?
	
	@AppStorage(Preferences.listViewSortOrder) private var itemSortOrder
	@AppStorage(Preferences.listViewSortDimension) private var itemSortDimension
	@AppStorage(Preferences.listViewShowComplication) private var showComplication
	
	let namespace: Namespace.ID
	
	var body: some View {
		listContent
			.animation(.default, value: currentLocation.isAuthorized)
			.animation(.default, value: items.count)
			.overlay { emptyStateOverlay }
			#if os(iOS)
			.listRowSpacing(appearance == .graphical ? 8 : 0)
			#endif
			.navigationTitle("Locations")
			.navigationSplitViewColumnWidth(ideal: 300)
			#if os(macOS)
			.searchable(text: Bindable(locationSearchService).queryFragment,
									placement: .automatic,
									prompt: "Search locations")
			#else
			.searchable(text: Bindable(locationSearchService).queryFragment,
									placement: .navigationBarDrawer,
									prompt: "Search locations")
			#endif
			.searchSuggestions { searchSuggestionsList }
	}

	private var listContent: some View {
		List(selection: $selectedLocation) {
			currentLocationRow
			savedLocationsList
		}
	}

	@ViewBuilder
	private var currentLocationRow: some View {
		if currentLocation.isAuthorized {
			ListRow(location: currentLocation)
				.tag(currentLocation.id)
			#if os(iOS)
				.onDrag { currentLocationDragItem }
				.matchedTransitionSource(id: currentLocation.id, in: namespace)
			#endif
		}
	}

	#if os(iOS)
	private var currentLocationDragItem: NSItemProvider {
		let userActivity = NSUserActivity(activityType: DetailView<CurrentLocation>.userActivity)
		userActivity.title = "See daylight for current location"
		userActivity.targetContentIdentifier = currentLocation.id
		return NSItemProvider(object: userActivity)
	}
	#endif

	private var savedLocationsList: some View {
		ForEach(sortedItems) { item in
			savedLocationRow(for: item)
		}
		.onDelete(perform: deleteItems)
	}

	@ViewBuilder
	private func savedLocationRow(for item: SavedLocation) -> some View {
		if let tag = item.uuid?.uuidString {
			ListRow(location: item)
				.contextMenu {
					savedLocationContextMenu(for: item)
				} preview: {
					savedLocationPreview(for: item)
				}
				#if os(iOS)
				.onDrag { savedLocationDragItem(for: item) }
				.matchedTransitionSource(id: tag, in: namespace)
				#endif
				.tag(tag)
		}
	}

	private func savedLocationContextMenu(for item: SavedLocation) -> some View {
		Section(item.title!) {
			Button(role: .destructive) {
				deleteItem(item)
			} label: {
				Label("Delete Location", systemImage: "trash")
			}
		}
	}

	private func savedLocationPreview(for item: SavedLocation) -> some View {
		Form {
			if let solar = Solar(for: timeMachine.date, coordinate: item.coordinate) {
				DailyOverview(solar: solar, location: item)
			}
		}
		.withTimeMachine(.solsticeTimeMachine)
	}

	#if os(iOS)
	private func savedLocationDragItem(for item: SavedLocation) -> NSItemProvider {
		let userActivity = NSUserActivity(activityType: DetailView<SavedLocation>.userActivity)
		let title: String = item.title ?? "location"
		userActivity.title = "See daylight for \(title)"
		userActivity.targetContentIdentifier = item.uuid?.uuidString
		return NSItemProvider(object: userActivity)
	}
	#endif

	@ViewBuilder
	private var emptyStateOverlay: some View {
		if !currentLocation.isAuthorized && items.isEmpty {
			ContentUnavailableView(
				"No locations",
				systemImage: "magnifyingglass",
				description: Text("Search for a location or enable location services")
			)
		}
	}

	private var searchSuggestionsList: some View {
		ForEach(locationSearchService.searchResults, id: \.hashValue) { result in
			LocationSearchResultRow(
				searchService: locationSearchService,
				items: Array(items),
				result: result
			)
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
	@Namespace static private var namespace
	static var previews: some View {
		NavigationStack {
			SidebarListView(namespace: namespace)
		}
			.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
			.withTimeMachine(.solsticeTimeMachine)
			.environment(CurrentLocation())
			.environment(LocationSearchService())
	}
}

fileprivate extension SidebarListView {
	struct ListRow<Location: ObservableLocation>: View {
		@AppStorage(Preferences.listViewAppearance) private var appearance
		var location: Location
		
		var body: some View {
			switch appearance {
			#if os(iOS)
			case .graphical:
				GraphicalLocationListRow(location: location)
			#endif
			default:
				LocationListRow(location: location)
			}
		}
	}
}
