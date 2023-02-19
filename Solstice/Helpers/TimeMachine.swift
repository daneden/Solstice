//
//  TimeMachine.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import Foundation
import Combine
import SwiftUI

class TimeMachine: ObservableObject {
	@Published var isOn = false
	@Published var referenceDate = Date()
	@Published var targetDate = Date()
	
	var date: Date {
		guard isOn else { return referenceDate }
		let time = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: referenceDate)
		return Calendar.autoupdatingCurrent.date(bySettingHour: time.hour ?? 0,
																									 minute: time.minute ?? 0,
																									 second: time.second ?? 0,
																									 of: targetDate) ?? targetDate
	}
}
