//
//  SavedLocation++.swift
//  Solstice
//
//  Created by Daniel Eden on 04/07/2024.
//

import Foundation

extension SavedLocation {
	struct CodableRepresentation: Codable, AnyLocation {
		var title: String?
		var subtitle: String?
		var latitude: Double
		var longitude: Double
		var timeZoneIdentifier: String?
		var uuid: UUID?
	}
	
	var codableRepresentation: CodableRepresentation {
		CodableRepresentation(title: title,
													subtitle: subtitle,
													latitude: latitude,
													longitude: longitude,
													timeZoneIdentifier: timeZoneIdentifier,
													uuid: uuid)
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
