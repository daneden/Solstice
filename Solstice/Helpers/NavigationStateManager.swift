//
//  NavigationStateManager.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

class NavigationStateManager: ObservableObject {
	@Published var navigationSelection: NavigationSelection?
	@Published var temporaryLocation: TemporaryLocation?
}
