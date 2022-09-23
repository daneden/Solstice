//
//  SidebarView.swift
//  Solstice
//
//  Created by Daniel Eden on 16/09/2022.
//

import SwiftUI

enum ActiveLocation: Hashable {
	case realLocation
	case savedLocation(_ location: SavedLocation)
}

struct SidebarView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@FetchRequest(entity: SavedLocation.entity(), sortDescriptors: []) var locations: FetchedResults<SavedLocation>
	
	var body: some View {
		List {
			if LocationManager.shared.locationAvailable {
				NavigationLink(value: ActiveLocation.realLocation) {
					Label("Current Location", systemImage: "location")
				}
			}
			ForEach(locations) { location in
				Text(location.nickname ?? location.localityName ?? "")
			}
		}
		.toolbar {
			ToolbarItem {
				Button {
					
				} label: {
					Label("Add Location", systemImage: "plus")
				}
			}
		}
		.navigationTitle("Solstice")
	}
}

struct SidebarView_Previews: PreviewProvider {
	static let persistenceController = PersistenceController.preview
	static var previews: some View {
		SidebarView()
			.environment(\.managedObjectContext, persistenceController.container.viewContext)
	}
}
