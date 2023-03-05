//
//  TimeInterval++.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Foundation

extension TimeInterval {
	var localizedString: String {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		formatter.allowedUnits = [.hour, .minute, .second]
		
		let string = formatter.string(from: abs(self)) ?? ""
		return string
	}
	
	var abbreviatedHourString: String {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .abbreviated
		formatter.allowedUnits = [.hour]
		formatter.maximumUnitCount = 1
		
		return formatter.string(from: self) ?? ""
	}
}
