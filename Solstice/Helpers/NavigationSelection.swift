//
//  NavigationSelection.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import Foundation

enum NavigationSelection: Hashable, Codable {
	case currentLocation
	case savedLocation(id: UUID?)
}
