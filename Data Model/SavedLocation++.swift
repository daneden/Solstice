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
