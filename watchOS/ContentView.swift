//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI
import Solar

struct ContentView: View {
	@Environment(\.scenePhase) var scenePhase
	@EnvironmentObject var currentLocation: CurrentLocation
	@EnvironmentObject var timeMachine: TimeMachine
	
	@State var selectedLocation: String?
	
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
		if #available(watchOS 10, *) {
			NavigationSplitView {
				List(selection: $selectedLocation) {
					if currentLocation.authorizationStatus == .notDetermined {
						LocationPermissionScreenerView()
					}
					
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
							DaylightSummaryRow(location: currentLocation)
								.tag(currentLocation.id)
								.listRowBackground(
									Solar(for: timeMachine.date, coordinate: currentLocation.coordinate)?
										.view
										.clipShape(.buttonBorder)
								)
						}
						
						ForEach(sortedItems) { item in
							if let tag = item.uuid?.uuidString {
								DaylightSummaryRow(location: item)
									.tag(tag)
									.listRowBackground(
										Solar(for: timeMachine.date, coordinate: item.coordinate)?
											.view
											.clipShape(.buttonBorder)
									)
							}
						}
					}
				}
			} detail: {
				switch selectedLocation {
				case currentLocation.id:
					DetailView(location: currentLocation)
						.containerBackground(for: .navigation) {
							if let solar = Solar(for: timeMachine.date, coordinate: currentLocation.coordinate) {
								solar.view
							}
						}
				case .some(let id):
					if let item = items.first(where: { $0.uuid?.uuidString == id }) {
						DetailView(location: item)
							.containerBackground(for: .navigation) {
								if let solar = Solar(for: timeMachine.date, coordinate: item.coordinate) {
									solar.view
								}
							}
					} else {
						placeholderView
					}
				case .none:
					placeholderView
				}
			}
		} else {
			fallbackBody
		}
	}
	
	var fallbackBody: some View {
		NavigationStack {
			switch currentLocation.authorizationStatus {
			case .notDetermined:
				LocationPermissionScreenerView()
			case .authorizedAlways, .authorizedWhenInUse:
				DetailView(location: currentLocation)
			case .denied, .restricted:
				Text("Solstice on Apple Watch requires location access in order to show local sunrise and sunset times. For custom and saved locations, use Solstice on iPhone, iPad, or Mac.")
			@unknown default:
				fatalError()
			}
		}
		.navigationTitle(Text(verbatim: "Solstice"))
		.onChange(of: scenePhase) { _ in
			timeMachine.referenceDate = Date()
			if currentLocation.isAuthorized,
				 scenePhase != .background {
				currentLocation.requestLocation()
			}
		}
		.onReceive(timer) { _ in
			timeMachine.referenceDate = Date()
			if currentLocation.isAuthorized {
				currentLocation.requestLocation()
			}
		}
	}
		
		var placeholderView: some View {
			VStack {
				Image("Solstice.SFSymbol")
					.foregroundStyle(.tertiary)
			}
		}
}

#Preview {
	ContentView()
		.environmentObject(TimeMachine.preview)
		.environmentObject(CurrentLocation())
}
