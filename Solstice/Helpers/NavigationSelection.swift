//
//  NavigationSelection.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import Foundation

enum NavigationSelection: Hashable {
	case currentLocation
	case savedLocation(id: UUID?)
}

extension NavigationSelection: Codable {
	enum CodingKeys: CodingKey {
		case currentLocation
		case savedLocation
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		switch self {
		case .currentLocation:
			try container.encode(true, forKey: .currentLocation)
		case .savedLocation(let id):
			try container.encode(id, forKey: .savedLocation)
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let key = container.allKeys.first
		
		switch key {
		case .currentLocation:
			self = .currentLocation
		case .savedLocation:
			let id = try container.decode(UUID.self, forKey: .savedLocation)
			self = .savedLocation(id: id)
		default:
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to decode enum"))
		}
	}
}

extension NavigationSelection: RawRepresentable {
	init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
		let result = try? JSONDecoder().decode(Self.self, from: data) else {
			return nil
		}
		
		self = result
	}
	
	var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
					let result = String(data: data, encoding: .utf8) else {
			return "{}"
		}
		
		return result
	}
}
