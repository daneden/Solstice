//
//  SavedLocation++.swift
//  Solstice
//
//  Created by Daniel Eden on 04/07/2024.
//

import CoreData
import Foundation

extension SavedLocation {
	/// The index that places a new location at the end of the manual order.
	static func nextSortIndex(in context: NSManagedObjectContext) -> Int64 {
		let request = SavedLocation.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.sortIndex, ascending: false)]
		request.fetchLimit = 1
		let highest = (try? context.fetch(request))?.first?.sortIndex ?? -1
		return highest + 1
	}

	static let nycUUIDString = "7AAA4D87-4402-4D0E-A35E-2D84641A71BE"

	static var defaultData: [LocationData] {
		guard let defaultDataUrl = Bundle.main.url(forResource: "defaultData", withExtension: "json") else {
			print("No URL for defaultData.json")
			return []
		}

		do {
			let defaultDataFileData = try Data(contentsOf: defaultDataUrl)
			return try JSONDecoder().decode([LocationData].self, from: defaultDataFileData)
		} catch {
			print(error.localizedDescription)
			return []
		}
	}

	/// Inserts the default locations into `context`. Saving is left to the caller.
	static func insertDefaults(into context: NSManagedObjectContext) {
		for entry in defaultData {
			let location = SavedLocation(context: context)
			location.title = entry.title
			location.subtitle = entry.subtitle
			location.uuid = entry.uuid
			location.latitude = entry.latitude
			location.longitude = entry.longitude
			location.timeZoneIdentifier = entry.timeZoneIdentifier
		}
	}
}
