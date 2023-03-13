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
	@Published var controlsVisible = false
	
	var offset: Binding<Double> {
		Binding<Double>(get: {
			Double(Calendar.current.dateComponents([.day], from: self.referenceDate, to: self.targetDate).day ?? 0)
		}, set: { newValue in
			self.targetDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: Int(newValue), to: self.referenceDate) ?? self.referenceDate
		})
	}
	
	var date: Date {
		guard isOn else { return referenceDate }
		let time = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: referenceDate)
		return Calendar.autoupdatingCurrent.date(bySettingHour: time.hour ?? 0,
																									 minute: time.minute ?? 0,
																									 second: time.second ?? 0,
																									 of: targetDate) ?? targetDate
	}
}
