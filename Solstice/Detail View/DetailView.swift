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
	@SceneStorage("selectedLocation") private var selectedLocation: String?
	
	var navBarTitleText: Text {
		guard let title = location.title else {
			return location is CurrentLocation ? Text("Current Location") : Text(verbatim: "Solstice")
		}
		
		return Text(title)
	}
	
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
				#if os(watchOS)
					.padding(.vertical, 8)
				#endif
			}
			.formStyle(.grouped)
			.navigationTitle(navBarTitleText)
			.toolbar {
				toolbarItems
			}
			.task(id: timeMachine.isOn) {
				if timeMachine.isOn {
					withAnimation {
						scrollProxy.scrollTo("timeMachineView")
					}
				}
			}
			.task(id: timeMachine.targetDate) {
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
			#if os(watchOS)
			.modify {
				if #available(watchOS 10, *) {
					if let solar {
						$0.containerBackground(
							SkyGradient(solar: solar),
							for: .navigation
						)
					} else {
						$0
					}
				} else {
					$0
				}
			}
			#endif
		}
	}
	
	var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: location.coordinate)
	}
	
	var toolbarItemPlacement: ToolbarItemPlacement {
		#if os(macOS)
		return .automatic
		#else
		if #available(watchOS 10, *) {
			return .topBarTrailing
		} else {
			return .automatic
		}
		#endif
	}
	
	@ToolbarContentBuilder
	var toolbarItems: some ToolbarContent {
		#if os(watchOS)
		ToolbarItem(id: "timeMachineToggle", placement: toolbarItemPlacement) {
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
							Label("Close", systemImage: "xmark")
						}
					}
				}
			}
		}
		#else
		ToolbarItem(id: "timeMachineToggle") {
			Toggle(isOn: $timeMachine.isOn.animation()) {
				Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
			}
		}
		#endif
		
		if let location = location as? TemporaryLocation {
			ToolbarItem {
				Button {
					dismiss()
					withAnimation {
						if let id = try? location.saveLocation(to: viewContext) {
							selectedLocation = id.uuidString
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

#Preview {
	NavigationStack {
		DetailView(location: TemporaryLocation.placeholderLondon)
	}
	.environmentObject(TimeMachine.preview)
}
