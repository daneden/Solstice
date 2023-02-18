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
	@Published var timeTravelOffset: Double = 0.0
	@Published var targetDate: Date = Date()
	
	var date: Date {
		Date().addingTimeInterval(Date().distance(to: targetDate))
		//Calendar.autoupdatingCurrent.date(byAdding: .day, value: Int(timeTravelOffset), to: Date()) ?? Date()
	}
	
	var isActive: Bool { !date.isToday }
	
	func resetTimeMachine() {
		withAnimation {
			timeTravelOffset = 0
			targetDate = Date()
		}
	}
}
