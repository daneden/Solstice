//
//  CLLocationCoordinate2D+RawRepresentable.swift
//  Solstice
//
//  Created by Daniel Eden on 05/04/2023.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: RawRepresentable {
	public init?(rawValue: String) {
		let parts = rawValue.split(separator: ",", maxSplits: 2)
		guard let lat = Double(parts.first ?? .init()), let long = Double(parts.last ?? .init()) else {
			return nil
		}
		
		self = CLLocationCoordinate2D(latitude: lat, longitude: long)
	}
	
	public var rawValue: String {
		"\(latitude),\(longitude)"
	}
}
