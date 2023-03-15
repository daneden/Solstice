//
//  TimeInterval++.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Foundation

extension TimeInterval {
	var localizedString: String {
		Duration.seconds(abs(self)).formatted(.units(maximumUnitCount: 2))
	}
	
	var abbreviatedHourString: String {
		Duration.seconds(self).formatted(.units(allowed: [.hours]))
	}
}
