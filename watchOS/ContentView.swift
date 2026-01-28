//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI
import SunKit
import TimeMachine

struct ContentView: View {
	@Environment(\.scenePhase) var scenePhase
	@Environment(CurrentLocation.self) var currentLocation
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	
	@SceneStorage("selectedLocation") private var selectedLocation: String?
	
	private let timer = Timer.publish(every: 60, on: RunLoop.main, in: .common).autoconnect()
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
	var sortedItems: [SavedLocation] {
		items.sorted { lhs, rhs in
			return lhs.timeZone.secondsFromGMT() < rhs.timeZone.secondsFromGMT()
		}
	}
	
	var body: some View {
		NavigationSplitView {
			List(selection: $selectedLocation) {
				Section {
					if !currentLocation.isAuthorized && items.isEmpty {
						VStack {
							Text("No locations")
								.font(.headline)
							Text("Search for a location or enable location services")
						}
						.frame(maxWidth: .infinity)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
					}
					
					if currentLocation.isAuthorized {
						LocationListRow(location: currentLocation)
							.tag(currentLocation.id)
							.listRowBackground(
								Sun(for: timeMachine.date, coordinate: currentLocation.coordinate)
									.view
									.clipShape(.rect(cornerRadius: 20, style: .continuous))
							)
					}

					ForEach(sortedItems) { item in
						if let tag = item.uuid?.uuidString {
							LocationListRow(location: item)
								.tag(tag)
								.listRowBackground(
									Sun(for: timeMachine.date, coordinate: item.coordinate)
										.view
										.clipShape(.rect(cornerRadius: 20, style: .continuous))
								)
						}
					}
				} footer: {
					Text("Locations are synced via iCloud. Delete or add new locations by using Solstice on Mac, iPhone, iPad, or Apple Vision Pro")
				}
			}
			.navigationTitle(Text(verbatim: "Solstice"))
			.timeTravelToolbar()
		} detail: {
			switch selectedLocation {
			case currentLocation.id:
				DetailView(location: currentLocation)
					.containerBackground(for: .navigation) {
						if let sun = Sun(for: timeMachine.date, coordinate: currentLocation.coordinate) {
							sun.view
						}
					}
					.timeTravelToolbar()
			case .some(let id):
				if let item = items.first(where: { $0.uuid?.uuidString == id }) {
					DetailView(location: item)
						.containerBackground(for: .navigation) {
							if let sun = Sun(for: timeMachine.date, coordinate: item.coordinate) {
								sun.view
							}
						}
						.timeTravelToolbar()
				} else {
					placeholderView
				}
			case .none:
				placeholderView
			}
		}
		.resolveDeepLink(sortedItems)
		.withTimeMachine(.solsticeTimeMachine)
	}
		
	var placeholderView: some View {
		Image(.solstice)
			.foregroundStyle(.tertiary)
	}
}

#Preview {
	ContentView()
		.withTimeMachine(.solsticeTimeMachine)
		.environment(CurrentLocation())
}
