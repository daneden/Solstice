//
//  DeduplicateLocationRecordsModifier.swift
//  Solstice
//
//  Created by Daniel Eden on 14/08/2025.
//

import SwiftUI
import CoreData
import CoreLocation

struct DeduplicateLocationRecordsModifier: ViewModifier {
	@Environment(\.managedObjectContext) private var context
	@FetchRequest(sortDescriptors: []) private var locations: FetchedResults<SavedLocation>
	
	func body(content: Content) -> some View {
		content
			.task(id: locations.count) {
				// Phase 1: Deduplicate by UUID
				var seenUUIDs = Set<UUID>()
				for location in locations {
					if let uuid = location.uuid {
						if seenUUIDs.contains(uuid) {
							context.delete(location)
						} else {
							seenUUIDs.insert(uuid)
						}
					}
				}
				
				// Phase 2: Deduplicate by name and proximity (within 1km)
				var kept: [(title: String?, coordinate: CLLocationCoordinate2D)] = []
				for location in locations where !context.deletedObjects.contains(location) {
					guard let title = location.title else { continue }
					let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
					let newLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
					let duplicate = kept.first { keptTitle, keptCoord in
						keptTitle == title && newLoc.distance(from: CLLocation(latitude: keptCoord.latitude, longitude: keptCoord.longitude)) < 1000
					}
					if duplicate != nil {
						context.delete(location)
					} else {
						kept.append((title, coord))
					}
				}
				
				if context.hasChanges {
					do {
						try context.save()
					} catch {
						print("Failed to delete duplicate locations: \(error)")
					}
				}
			}
	}
}

extension View {
	func deduplicateLocationRecords() -> some View {
		self.modifier(DeduplicateLocationRecordsModifier())
	}
}
