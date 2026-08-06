//
//  ContentView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import CoreData
import Suite
import SwiftUI
import TimeMachine
#if canImport(AppKit)
	import AppKit
#endif

struct ContentView: View {
	@Namespace private var namespace
	@AppStorage(Preferences.listViewSortDimension) private var itemSortDimension
	@AppStorage(Preferences.listViewSortOrder) private var itemSortOrder
	@Environment(\.managedObjectContext) private var context
	@Environment(\.openWindow) private var openWindow
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@SceneStorage("selectedLocation") private var selectedLocation: String?

	#if os(macOS)
		/// Fallback storage for macOS where SceneStorage doesn't persist across app launches
		@AppStorage("lastSelectedLocation") private var lastSelectedLocation: String?
	#endif

	@Environment(\.scenePhase) private var scenePhase
	@Environment(\.timeMachine) private var timeMachine: TimeMachine
	@Environment(CurrentLocation.self) var currentLocation
	@Environment(LocationSearchService.self) var locationSearchService

	@State private var settingsViewOpen = false
	@State private var sidebarVisibility = NavigationSplitViewVisibility.doubleColumn

	#if os(iOS)
		/// The zoom transition needs a rendered `matchedTransitionSource` row. When the
		/// app cold-launches with a restored selection, the sidebar list has never been
		/// built, and attaching the zoom transition then leaves the interactive pop
		/// gesture inert. Enable it only once the list has been on screen.
		@State private var zoomTransitionSourceExists = false
	#endif

	@FetchRequest(sortDescriptors: []) private var locations: FetchedResults<SavedLocation>

	var body: some View {
		NavigationSplitView(columnVisibility: $sidebarVisibility) {
			SidebarListView(namespace: namespace)
				.toolbar {
					toolbarItems
				}
			#if os(macOS)
				.frame(minWidth: 256)
			#endif
		} detail: {
			NavigationStack {
				Group {
					switch selectedLocation {
					case currentLocation.id:
						DetailView(location: currentLocation)
					case let .some(id):
						if let location = locations.first(where: { $0.uuid?.uuidString == id }) {
							DetailView(location: location)
								.id(location)
						} else {
							placeholderView
						}
					default:
						placeholderView
					}
				}
			}
			#if os(iOS)
			.modify { content in
				if zoomTransitionSourceExists {
					content
						.navigationTransition(.zoom(sourceID: selectedLocation ?? "", in: namespace))
				} else {
					content
				}
			}
			.onChange(of: selectedLocation, initial: true) { _, newValue in
				if newValue == nil {
					zoomTransitionSourceExists = true
				}
			}
			#endif
		}
		.navigationSplitViewStyle(.balanced)
		.sheet(item: Bindable(locationSearchService).location) { value in
			NavigationStack {
				DetailView(location: value)
			}
			#if os(macOS)
			.frame(minWidth: 600, minHeight: 400)
			#endif
			.timeMachineOverlay()
		}
		.timeMachineOverlay()
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
		#if os(iOS)
			.sheet(isPresented: $settingsViewOpen) {
				SettingsView()
					.presentationDetents(horizontalSizeClass == .regular ? [.large] : [.large, .medium])
			}
		#endif
			.deduplicateLocationRecords()
			.capturingScreenshots()
			.task(id: scenePhase) {
				switch scenePhase {
				#if !os(watchOS)
					case .background:
						await NotificationManager.scheduleNotifications(location: currentLocation.location)
				#endif
				case .active:
					// A suspended app misses the TimeMachine's minutely reference-date ticks;
					// waking after hours would otherwise show the pre-sleep sky and sun position
					// until the next tick lands. Never while a capture has pinned the clock.
					if ScreenshotLaunch.displayDate == nil {
						timeMachine.updateReferenceDate()
					}
					// Skip the location-permission request during screenshot capture: on macOS
					// its system dialog steals focus and hides the app window from the test runner.
					if !ScreenshotLaunch.isCapturing {
						currentLocation.requestLocation()
					}
				default:
					return
				}
			}
		#if os(macOS)
			.onAppear {
				// Restore selection from AppStorage if SceneStorage is empty
				if selectedLocation == nil, let lastSelected = lastSelectedLocation {
					selectedLocation = lastSelected
				}
			}
			.onChange(of: selectedLocation) { _, newValue in
				// Sync selection to AppStorage for persistence across launches
				lastSelectedLocation = newValue
			}
		#endif
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
				.accessibilityIdentifier(A11y.settingsButton)
			}
		#endif
	}
}

#Preview {
	ContentView()
		.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
		.withTimeMachine(.solsticeTimeMachine)
		.environment(CurrentLocation())
		.environment(LocationSearchService())
}
