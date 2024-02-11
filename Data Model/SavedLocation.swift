//
//  SavedLocation.swift
//  Solstice
//
//  Created by Daniel Eden on 11/02/2024.
//
//

import Foundation
import SwiftData


@Model class SavedLocation {
    var latitude: Double = 51.509865
    var longitude: Double = -0.118092
    var subtitle: String?
    var timeZoneIdentifier: String? = "GMT"
    var title: String = ""
    var uuid: UUID = UUID()
    public init() {

    }
    
}
