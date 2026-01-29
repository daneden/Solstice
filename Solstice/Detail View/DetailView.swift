//
//  DetailView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import SunKit
import Suite
import TimeMachine

struct DetailView<Location: ObservableLocation>: View {
	static var userActivity: String {
		Constants.viewLocationActivityType
	}
	
	@Environment(\.managedObjectContext) var viewContext
	@Environment(\.dismiss) var dismiss
	
	var location: Location
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	#if !os(watchOS)
	@Environment(LocationSearchService.self) var locationSearchService
	#endif
	@State private var showRemainingDaylight = false
	@State private var showShareSheet = false
	@State private var cachedSun: Sun?
	@State private var lastLocationKey: String?

	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@SceneStorage("selectedLocation") private var selectedLocation: String?

	var sun: Sun? { cachedSun }

	private var locationKey: String {
		"\(location.coordinate.latitude),\(location.coordinate.longitude)"
	}
	
	var navBarTitleText: Text {
		guard let title = location.title else {
			return location is CurrentLocation ? Text("Current Location") : Text(verbatim: "Solstice")
		}
		
		return Text(title)
	}
	
	var body: some View {
		Form {
			if let sun {
				DailyOverview(sun: sun, location: location)
			}
			
			AnnualOverview(location: location)
		}
		.formStyle(.grouped)
		.navigationTitle(navBarTitleText)
		.toolbar {
			toolbarItems
		}
		.userActivity(Self.userActivity) { userActivity in
			var navigationSelection: String? = nil
			
			if let location = location as? SavedLocation {
				navigationSelection = location.uuid?.uuidString
			} else if let location = location as? CurrentLocation {
				navigationSelection = location.id
			}
			
			userActivity.title = "See daylight for \(location is CurrentLocation ? "current location" : location.title ?? "location")"
			
			userActivity.targetContentIdentifier = navigationSelection
			userActivity.isEligibleForSearch = true
			userActivity.isEligibleForHandoff = false
		}
		#if os(watchOS)
		.modify {
			if let sun {
				$0.containerBackground(
					SkyGradient(sun: sun),
					for: .navigation
				)
			} else {
				$0
			}
		}
		#endif
		.sheet(isPresented: $showShareSheet) {
			if let sun {
				ShareSolarChartView(sun: sun, location: location, chartAppearance: chartAppearance)
			}
		}
		.onChange(of: timeMachine.date) { _, newDate in
			cachedSun?.setDate(newDate)
		}
		.onChange(of: locationKey) { _, _ in
			cachedSun = Sun(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
			lastLocationKey = locationKey
		}
		.onAppear {
			if cachedSun == nil || lastLocationKey != locationKey {
				cachedSun = Sun(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
				lastLocationKey = locationKey
			}
		}
	}
	
	var toolbarItemPlacement: ToolbarItemPlacement {
		#if os(macOS)
		return .automatic
		#else
		return .topBarTrailing
		#endif
	}
	
	@ToolbarContentBuilder
	var toolbarItems: some ToolbarContent {
		#if !os(macOS)
		ToolbarItem(placement: .topBarTrailing) {
			Button("Share...", systemImage: "square.and.arrow.up") {
				showShareSheet.toggle()
			}
		}
		#endif
		
		if let location = location as? TemporaryLocation {
			ToolbarItem(placement: .confirmationAction) {
				Button {
					dismiss()
					withAnimation {
						if let id = try? location.saveLocation(to: viewContext) {
							selectedLocation = id.uuidString
						}
					}
				} label: {
					Label("Save Location", systemImage: "plus")
						.backportCircleSymbolVariant()
				}
			}
		}
		
		#if !os(watchOS)
		if locationSearchService.location != nil {
			ToolbarItem(placement: .cancellationAction) {
				Button {
					locationSearchService.location = nil
				} label: {
					Text("Close")
				}
			}
		}
		#endif
	}
}

#Preview {
	NavigationStack {
		DetailView(location: TemporaryLocation.placeholderLondon)
	}
	.withTimeMachine(.solsticeTimeMachine)
	.environment(LocationSearchService())
}
