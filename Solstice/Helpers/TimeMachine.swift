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
	@Published var referenceDate = Date()
	@Published var targetDate = Date()
	
	var date: Date {
		referenceDate.addingTimeInterval(referenceDate.distance(to: targetDate))
		//Calendar.autoupdatingCurrent.date(byAdding: .day, value: Int(timeTravelOffset), to: Date()) ?? Date()
	}
	
	var isActive: Bool { !date.isToday }
	
	func resetTimeMachine() {
		withAnimation {
			targetDate = Date()
		}
	}
}
