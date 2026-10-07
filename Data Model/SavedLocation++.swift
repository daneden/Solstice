//
//  SavedLocation++.swift
//  Solstice
//
//  Created by Daniel Eden on 04/07/2024.
//

import CoreData
import Foundation

extension SavedLocation {
	typealias CodableRepresentation = LocationData

	var codableRepresentation: LocationData {
		LocationData(
			title: title,
			subtitle: subtitle,
			latitude: latitude,
			longitude: longitude,
			timeZoneIdentifier: timeZoneIdentifier,
			uuid: uuid
		)
	}
}

extension SavedLocation {
	/// The index that places a new location at the end of the manual order.
	static func nextSortIndex(in context: NSManagedObjectContext) -> Int64 {
		let request = SavedLocation.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.sortIndex, ascending: false)]
		request.fetchLimit = 1
		let highest = (try? context.fetch(request))?.first?.sortIndex ?? -1
		return highest + 1
	}
}

extension SavedLocation {
	static let nycUUIDString = "7AAA4D87-4402-4D0E-A35E-2D84641A71BE"

	static var defaultData: [SavedLocation.CodableRepresentation] {
		guard let defaultDataUrl = Bundle.main.url(forResource: "defaultData", withExtension: "json") else {
			print("No URL for defaultData.json")
			return []
		}

		do {
			let defaultDataFileData = try Data(contentsOf: defaultDataUrl)
			return try JSONDecoder().decode([SavedLocation.CodableRepresentation].self, from: defaultDataFileData)
		} catch {
			print(error.localizedDescription)
			return []
		}
	}
}
