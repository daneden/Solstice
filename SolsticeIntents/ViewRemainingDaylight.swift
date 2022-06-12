//
//  ViewRemainingDaylight.swift
//  Solstice
//
//  Created by Daniel Eden on 12/06/2022.
//

import Foundation
import AppIntents

struct ViewRemainingDaylight: AppIntent, CustomIntentMigratedAppIntent {
    static _const let intentClassName = "ViewRemainingDaylightIntent"
    
    static var title: LocalizedStringResource = "View Remaining Daylight"
    static var description = IntentDescription("View how much daylight is remaining today, based on the time until sunset.")

    static var parameterSummary: some ParameterSummary {
      Summary("Get the remaining daylight for your current location")
    }
    
  func perform() async throws -> some PerformResult {
    let calculator = SolarCalculator()
    let isDaytime = calculator.today.begins.isInPast && calculator.today.ends.isInFuture
    
    if isDaytime {
      return .finished(value: Date().distance(to: calculator.today.ends))
    } else if calculator.today.ends.isInPast {
      return .finished(value: TimeInterval(0), dialog: "No more daylight today. The sun rises again tomorrow at \(calculator.tomorrow.begins.formatted(date: .omitted, time: .standard))")
    } else if calculator.today.begins.isInFuture {
      return .finished(value: calculator.today.duration)
    } else {
      return .finished(value: TimeInterval(0))
    }
  }
}

