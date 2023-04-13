//
//  DetailView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import Solar
import CoreLocation

struct DetailView<Location: ObservableLocation>: View {
	static var userActivity: String {
		"me.daneden.Solstice.viewLocation"
	}
	
	@Environment(\.managedObjectContext) var viewContext
	@Environment(\.dismiss) var dismiss
	
	@ObservedObject var location: Location
	@EnvironmentObject var timeMachine: TimeMachine
	#if !os(watchOS)
	@EnvironmentObject var locationSearchService: LocationSearchService
	#endif
	@State private var showRemainingDaylight = false
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@SceneStorage("selectedLocation") private var selectedLocation: NavigationSelection?
	
	var body: some View {
		ScrollViewReader { scrollProxy in
			Form {
				#if !os(watchOS)
				if timeMachine.isOn {
					TimeMachineView()
						.id("timeMachineView")
				}
				#endif
				
				if let solar {
					DailyOverview(solar: solar, location: location)
				} else {
					ProgressView {
						HStack {
							Spacer()
							Text("Calculating...")
							Spacer()
						}
						.padding()
					}
				}
				
				AnnualOverview(location: location)
			}
			.formStyle(.grouped)
			.navigationTitle(location.title ?? "Solstice")
			.toolbar {
				toolbarItems
			}
			.onChange(of: timeMachine.isOn) { newValue in
				if newValue == true {
					withAnimation {
						scrollProxy.scrollTo("timeMachineView")
					}
				}
			}
			.onChange(of: timeMachine.targetDate) { newValue in
				if timeMachine.isOn {
					withAnimation {
						scrollProxy.scrollTo("timeMachineView")
					}
				}
			}
			.userActivity(Self.userActivity) { userActivity in
				var navigationSelection: String? = nil
				
				if let location = location as? SavedLocation {
					navigationSelection = location.uuid?.uuidString
				} else if let location = location as? CurrentLocation {
					navigationSelection = location.id
				}
				
				userActivity.title = "See daylight for \(location is CurrentLocation ? "current location" : location.title!)"
				
				userActivity.targetContentIdentifier = navigationSelection
				userActivity.isEligibleForSearch = true
				userActivity.isEligibleForHandoff = false
			}
		}
	}
	
	var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: location.coordinate)
	}
	
	@ToolbarContentBuilder
	var toolbarItems: some ToolbarContent {
		ToolbarItem(id: "timeMachineToggle") {
			#if os(watchOS)
			Button {
				timeMachine.controlsVisible.toggle()
			} label: {
				Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
			}
			.sheet(isPresented: $timeMachine.controlsVisible) {
				Form {
					TimeMachineView()
				}
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button {
							timeMachine.controlsVisible.toggle()
						} label: {
							Text("Close")
						}
					}
				}
			}
			#else
			Toggle(isOn: $timeMachine.isOn.animation(.interactiveSpring())) {
				Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
			}
			#endif
			
		}
		
		if let location = location as? TemporaryLocation {
			ToolbarItem {
				Button {
					dismiss()
					withAnimation {
						if let id = try? location.saveLocation(to: viewContext) {
							selectedLocation = .savedLocation(id: id)
						}
					}
				} label: {
					Label("Save Location", systemImage: "plus.circle")
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

struct DetailView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			DetailView(location: TemporaryLocation.placeholderLondon)
		}
		.environmentObject(TimeMachine.preview)
		.previewDisplayName("Detail View: Temporary Location")
		
		NavigationStack {
			DetailView(location: CurrentLocation())
		}
		.previewDisplayName("Detail View: Current Location")
	}
}
