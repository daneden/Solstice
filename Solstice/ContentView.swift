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
			.navigationTransition(.zoom(sourceID: selectedLocation ?? "", in: namespace))
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
			.task {
				guard ScreenshotLaunch.isCapturing else { return }
				// Deterministic launch state: honor the forced selection, otherwise
				// start on the list (ignore any stale SceneStorage selection).
				selectedLocation = ScreenshotLaunch.forcedSelectedLocation
				if let offset = ScreenshotLaunch.timeOffsetDays {
					timeMachine.offset = Double(offset)
				}
				#if os(macOS)
					// Force the app frontmost so its window is presented for capture.
					NSApplication.shared.activate(ignoringOtherApps: true)
					// For the settings marketing shot, open the dedicated capture window (the
					// SwiftUI Settings scene can't be opened programmatically). DEBUG-only window.
					#if DEBUG
						if ScreenshotLaunch.macScreen == .settingsNotifications {
							try? await Task.sleep(for: .milliseconds(400))
							openWindow(id: "capture-settings")
						}
					#endif
				#endif
				#if os(visionOS)
					// For the solstice-info marketing shot, present the "About solstices and
					// equinoxes" window and dismiss the main one so it's captured alone.
					// The main window stays open behind — dismissing it leaves the info
					// window permanently dimmed (unfocused), and its glass backdrop is
					// what gives the front window its solid, readable look.
					if ScreenshotLaunch.visionScreen == .solsticeInfo {
						try? await Task.sleep(for: .milliseconds(400))
						openWindow(value: AnnualSolarEvent.juneSolstice)
					}
				#endif
			}
			.task(id: scenePhase) {
				switch scenePhase {
				#if !os(watchOS)
					case .background:
						await NotificationManager.scheduleNotifications(location: currentLocation.location)
				#endif
				case .active:
					// A suspended app misses the TimeMachine's minutely reference-date ticks;
					// waking after hours would otherwise show the pre-sleep sky and sun position
					// until the next tick lands.
					timeMachine.updateReferenceDate()
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
