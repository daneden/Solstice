//
//  NavigationStateManager.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation
import Combine

final class NavigationStateManager: ObservableObject, Codable {
	@Published var navigationSelection: NavigationSelection?
	@Published var temporaryLocation: TemporaryLocation?
	
	enum CodingKeys: CodingKey {
		case navigationSelection
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encodeIfPresent(navigationSelection, forKey: .navigationSelection)
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		navigationSelection = try container.decodeIfPresent(NavigationSelection.self, forKey: .navigationSelection)
	}
	
	init(navigationSelection: NavigationSelection? = nil, temporaryLocation: TemporaryLocation? = nil) {
		self.navigationSelection = navigationSelection
		self.temporaryLocation = temporaryLocation
	}
	
	var jsonData: Data? {
		get {
			try? JSONEncoder().encode(self)
		}
		set {
			guard let data = newValue,
						let model = try? JSONDecoder().decode(NavigationStateManager.self, from: data)
			else { return }
			self.navigationSelection = model.navigationSelection
		}
	}
	
	var objectWillChangeSequence: AsyncPublisher<Publishers.Buffer<ObservableObjectPublisher>> {
		objectWillChange
			.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
			.values
	}
}
