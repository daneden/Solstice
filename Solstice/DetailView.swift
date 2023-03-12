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
	@Environment(\.managedObjectContext) var viewContext
	@Environment(\.dismiss) var dismiss
	
	@ObservedObject var location: Location
	@EnvironmentObject var timeMachine: TimeMachine
	@EnvironmentObject var navigationState: NavigationStateManager
	@State private var showRemainingDaylight = false
	@State private var timeTravelVisible = false
	
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	
	var body: some View {
		Form {
			#if !os(watchOS)
			if timeMachine.isOn {
				TimeMachineView()
			}
			#endif
			
			if let solar {
				DailyOverview(solar: solar, location: location)
			}
			
			if let solar {
				AnnualOverview(solar: solar, location: location)
			}
		}
		.formStyle(.grouped)
		.navigationTitle(location.title ?? "Solstice")
		.toolbar {
			toolbarItems
		}
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
			}
			#else
			Toggle(isOn: $timeMachine.isOn.animation()) {
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
							navigationState.navigationSelection = .savedLocation(id: id)
						}
					}
				} label: {
					Label("Save Location", systemImage: "plus.circle")
				}
			}
		}
		
		if navigationState.temporaryLocation != nil {
			ToolbarItem(placement: .cancellationAction) {
				Button {
					navigationState.temporaryLocation = nil
				} label: {
					Text("Close")
				}
			}
		}
	}
}

extension DetailView {
	var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
	}
}

struct DetailView_Previews: PreviewProvider {
	static var previews: some View {
		DetailView(location: TemporaryLocation.placeholderLocation)
		.environmentObject(TimeMachine())
		.environmentObject(NavigationStateManager())
	}
}
