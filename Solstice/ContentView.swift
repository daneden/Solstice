//
//  ContentView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import CoreData

struct ContentView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@EnvironmentObject var timeMachine: TimeMachine
	@StateObject var currentLocation = CurrentLocation()
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
	@State private var addLocationSheetPresented = false
	
	var body: some View {
		NavigationView {
			List {
				#if !os(watchOS)
				TimeMachineView()
				#endif
				
				Section {
					NavigationLink {
						DetailView(location: currentLocation)
					} label: {
						DaylightSummaryRow(location: currentLocation)
					}
					
					ForEach(items) { item in
						NavigationLink {
							DetailView(location: item)
						} label: {
							DaylightSummaryRow(location: item)
						}
					}
					.onDelete(perform: deleteItems)
				} header: {
					Label("Locations", systemImage: "map")
				}
			}
			.toolbar {
				ToolbarItem {
					Button {
						addLocationSheetPresented = true
					} label: {
						Label("Add Item", systemImage: "plus")
					}
				}
				
				ToolbarItem(id: "timeMachineToggle") {
					Toggle(isOn: $timeMachine.isOn.animation()) {
						Label("Time Travel", systemImage: "clock.arrow.2.circlepath")
					}
				}
			}
			.navigationTitle("Solstice")
			
			Image("Solstice-Icon")
				.resizable()
				.foregroundStyle(.quaternary)
				.frame(width: 100, height: 100)
				.aspectRatio(contentMode: .fit)
		}
		#if !os(watchOS)
		.sheet(isPresented: $addLocationSheetPresented) {
			NavigationStack {
				AddLocationView()
			}
		}
		#endif
	}
	
	private func addItem() {
		withAnimation {
			let newItem = SavedLocation(context: viewContext)
			newItem.title = "New item at \(Date.now.formatted())"
			
			do {
				try viewContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nsError = error as NSError
				fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			offsets.map { items[$0] }.forEach(viewContext.delete)
			
			do {
				try viewContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nsError = error as NSError
				fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
	}
}

private let itemFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateStyle = .short
	formatter.timeStyle = .medium
	return formatter
}()

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	}
}
