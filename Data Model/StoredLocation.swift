//
//  SavedLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 11/02/2024.
//
//

import Foundation
import SwiftData


@Model
class SavedLocation {
	var title: String = ""
	var subtitle: String?
	
	var latitude: Double = 51.509865
	var longitude: Double = -0.118092
	
	var timeZoneIdentifier: String? = TimeZone.gmt.identifier
	var uuid: UUID = UUID()

	public init() {

	}
}
