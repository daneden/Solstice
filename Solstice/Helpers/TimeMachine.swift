//
//  TimeMachine.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2023.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class TimeMachine: ObservableObject {
	@Published var isOn = false
	@Published var referenceDate = Date()
	@Published var targetDate = Date()
	@Published var controlsVisible = false
	
	var offset: Binding<Double> {
		Binding<Double>(get: {
			Double(calendar.dateComponents([.day], from: self.referenceDate, to: self.targetDate).day ?? 0)
		}, set: { newValue in
			self.targetDate = calendar.date(byAdding: .day, value: Int(newValue), to: self.referenceDate) ?? self.referenceDate
		})
	}
	
	var date: Date {
		guard isOn else { return referenceDate }
		let time = calendar.dateComponents([.hour, .minute, .second], from: referenceDate)
		return calendar.date(bySettingHour: time.hour ?? 0,
																									 minute: time.minute ?? 0,
																									 second: time.second ?? 0,
																									 of: targetDate) ?? targetDate
	}
}

extension TimeMachine {
	static let preview = TimeMachine()
	static let shared = TimeMachine()
}
