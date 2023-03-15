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
	
	private var timer: Timer = .init()
	
	init(isOn: Bool = false, referenceDate: Date = Date(), targetDate: Date = Date(), controlsVisible: Bool = false) {
		self.isOn = isOn
		self.referenceDate = referenceDate
		self.targetDate = targetDate
		self.controlsVisible = controlsVisible
		self.timer = Timer(timeInterval: 60 * 60, repeats: true) { [weak self] timer in
			print("Updating timer")
			self?.referenceDate = Date()
		}
	}
	
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
