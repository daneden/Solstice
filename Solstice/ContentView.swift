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
	@AppStorage(Preferences.listViewOrderBy) private var itemSortDimension
	@AppStorage(Preferences.listViewSortOrder) private var itemSortOrder
	@AppStorage(Preferences.listViewShowComplication) private var showComplication
	
	@SceneStorage("navigationState") private var navigationStateData: Data?
	
	@Environment(\.scenePhase) var scenePhase
	@EnvironmentObject var currentLocation: CurrentLocation
	
	@StateObject var timeMachine = TimeMachine()
	@StateObject private var navigationState = NavigationStateManager()
	
	@State private var settingsViewOpen = false
	@State private var sidebarVisibility = NavigationSplitViewVisibility.doubleColumn
	
	@FetchRequest(sortDescriptors: []) private var items: FetchedResults<SavedLocation>
	
	private let timer = Timer.publish(every: 60, on: RunLoop.main, in: .common).autoconnect()
			
	var body: some View {
			NavigationSplitView(columnVisibility: $sidebarVisibility) {
				SidebarListView()
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
			.navigationSplitViewStyle(.balanced)
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
			.environmentObject(timeMachine)
			.task {
				for await _ in navigationState.objectWillChangeSequence {
					navigationStateData = navigationState.jsonData
				}
			}
			.onAppear {
				if let navigationStateData {
					navigationState.jsonData = navigationStateData
				}
			}
			.onChange(of: scenePhase) { _ in
				timeMachine.referenceDate = Date()
			}
			.onReceive(timer) { _ in
				timeMachine.referenceDate = Date()
			}
	}
	
	private var placeholderView: some View {
		Image("Solstice.SFSymbol")
			.resizable()
			.foregroundStyle(.quaternary)
			.frame(width: 100, height: 100)
			.aspectRatio(contentMode: .fit)
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

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
			.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
			.environmentObject(TimeMachine.preview)
			.environmentObject(CurrentLocation())
	}
}
