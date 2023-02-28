//
//  NavigationSelection.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import Foundation

enum NavigationSelection: Hashable {
	case currentLocation
	case savedLocation(id: SavedLocation.ID)
	case temporaryLocation(_ location: TemporaryLocation)
}
