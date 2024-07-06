//
//  CLLocationCoordinate2D+RawRepresentable.swift
//  Solstice
//
//  Created by Daniel Eden on 05/04/2023.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
	static var proxiedToTimeZone: CLLocationCoordinate2D {
		let offset = Double(TimeZone.current.secondsFromGMT()) / (60 * 60)
		return CLLocationCoordinate2D(latitude: 0, longitude: offset * 15)
	}
}

extension CLLocationCoordinate2D {
	var insideArcticCircle: Bool {
		latitude > 66.34
	}
	
	var insideAntarcticCircle: Bool {
		latitude < -66.34
	}
	
	var insidePolarCircle: Bool {
		insideArcticCircle || insideAntarcticCircle
	}
}
