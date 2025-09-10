//
//  ContentView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import CoreData
import Solar
import Suite

struct ContentView: View {
	@Namespace private var namespace
	@AppStorage(Preferences.listViewSortDimension) private var itemSortDimension
	@AppStorage(Preferences.listViewSortOrder) private var itemSortOrder
	@Environment(\.managedObjectContext) private var context
	@Environment(\.openWindow) private var openWindow
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	@SceneStorage("selectedLocation") private var selectedLocation: String?
	
	@Environment(\.scenePhase) private var scenePhase
	@EnvironmentObject var currentLocation: CurrentLocation
	
	@StateObject var timeMachine = TimeMachine()
	@StateObject var locationSearchService = LocationSearchService()
	
	@State private var settingsViewOpen = false
	@State private var sidebarVisibility = NavigationSplitViewVisibility.doubleColumn
	
	@FetchRequest(sortDescriptors: []) private var locations: FetchedResults<SavedLocation>
			
	var body: some View {
			NavigationSplitView(columnVisibility: $sidebarVisibility) {
				SidebarListView(namespace: namespace)
					.toolbar {
						toolbarItems
					}
				#if os(macOS)
					.navigationSplitViewColumnWidth(256)
				#endif
			} detail: {
				NavigationStack {
					switch selectedLocation {
					case currentLocation.id:
						DetailView(location: currentLocation)
					case .some(let id):
						if let location = locations.first(where: { $0.uuid?.uuidString == id }) {
							DetailView(location: location)
						} else {
							placeholderView
						}
					default:
						placeholderView
					}
				}
				#if os(iOS)
				.navigationTransition(.zoom(sourceID: selectedLocation ?? "", in: namespace))
				#endif
			}
			.navigationSplitViewStyle(.balanced)
			.sheet(item: $locationSearchService.location) { value in
					NavigationStack {
						DetailView(location: value)
					}
					#if os(macOS)
					.frame(minWidth: 600, minHeight: 400)
					#endif
					.timeMachineOverlay()
			}
			.environmentObject(locationSearchService)
			.timeMachineOverlay()
			.environmentObject(timeMachine)
			.onContinueUserActivity(DetailView<SavedLocation>.userActivity) { userActivity in
				if let selection = userActivity.targetContentIdentifier {
					selectedLocation = selection
				}
			}
			.onContinueUserActivity(DetailView<CurrentLocation>.userActivity) { userActivity in
				if userActivity.targetContentIdentifier == currentLocation.id {
					selectedLocation = currentLocation.id
				}
			}
			.resolveDeepLink(Array(locations))
			.overlay {
				TimelineView(.everyMinute) { timelineContext in
					Color.clear.task(id: timelineContext.date) {
						timeMachine.referenceDate = timelineContext.date
					}
				}
			}
			#if os(iOS)
			.sheet(isPresented: $settingsViewOpen) {
				SettingsView()
					.presentationDetents([.large, .medium])
			}
			#endif
			.deduplicateLocationRecords()
	}
	
	private var placeholderView: some View {
		ContentUnavailableView {
			Label("No location selected", image: .solstice)
		} description: {
			Text("Select a location to view details")
		}
	}
	
	@ToolbarContentBuilder
	private var toolbarItems: some ToolbarContent {
		ToolbarItem(placement: .primaryAction) {
			Menu {
				Picker(selection: $itemSortDimension.animation()) {
					Text("Timezone")
						.tag(Preferences.SortingFunction.timezone)
					
					Text("Daylight duration")
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
				Label("Sort locations", systemImage: "arrow.up.arrow.down")
					.backportCircleSymbolVariant()
			}
		}
			
		
#if os(visionOS)
		ToolbarItem {
			Button {
				openWindow(id: "settings")
			} label: {
				Label("Settings", systemImage: "ellipsis")
			}
		}
#elseif !os(macOS)
		ToolbarItem(placement: .navigation) {
			Button {
				settingsViewOpen = true
			} label: {
				Label("Settings", systemImage: "ellipsis")
			}
			.backportCircleSymbolVariant()
		}
#endif
	}
}

#Preview {
	ContentView()
		.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
		.environmentObject(TimeMachine.preview)
		.environmentObject(CurrentLocation())
}

