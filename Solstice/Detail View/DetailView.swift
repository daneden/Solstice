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
	@State private var solar: Solar?
	
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
		.task(id: timeMachine.date, priority: .background) {
			if solar != nil && timeMachine.isOn {
				do {
					try await Task.sleep(nanoseconds: 1_000_000)
					setSolarValue()
				} catch {
					
				}
			} else {
				setSolarValue()
			}
		}
	}
	
	func setSolarValue() {
		let newSolar = Solar(for: timeMachine.date, coordinate: location.coordinate.coordinate)
		
		if solar == nil {
			withAnimation { solar = newSolar }
		} else {
			solar = newSolar
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

struct DetailView_Previews: PreviewProvider {
	static var previews: some View {
		DetailView(location: TemporaryLocation.placeholderLocation)
		.environmentObject(TimeMachine())
		.environmentObject(NavigationStateManager())
	}
}
