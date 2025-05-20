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
	
	var isOn: Binding<Bool> {
		Binding<Bool> {
			self.offsetAmount != 0
		} set: { newValue in
			self.offset.wrappedValue = newValue ? 0.1 : 0
		}
	}
	
	var offsetAmount: Double {
		offset.wrappedValue
	}
	
	var date: Date {
		guard isOn.wrappedValue else { return referenceDate }
		let time = calendar.dateComponents([.hour, .minute, .second], from: referenceDate)
		return calendar.date(bySettingHour: time.hour ?? 0,
																									 minute: time.minute ?? 0,
																									 second: time.second ?? 0,
																									 of: targetDate) ?? targetDate
	}
	
	func dateLabel(context: DateFormatter.Context = .standalone) -> String {
		let formatter = DateFormatter()
		formatter.formattingContext = context
		formatter.doesRelativeDateFormatting = true
		formatter.timeStyle = .none
		formatter.dateStyle = .medium
		
		return formatter.string(from: date)
	}
}

extension TimeMachine {
	static let preview = TimeMachine()
	static let shared = TimeMachine()
}
