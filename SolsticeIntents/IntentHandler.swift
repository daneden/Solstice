//
//  IntentHandler.swift
//  SolsticeIntents
//
//  Created by Daniel Eden on 11/04/2021.
//

import Intents

class IntentHandler: INExtension {
  override func handler(for intent: INIntent) -> Any {
    switch intent {
    case is ViewDaylightIntent:
      return ViewDaylightIntentHandler()
    case is ViewRemainingDaylightIntent:
      return ViewRemainingDaylightIntentHandler()
    default:
      return self
    }
  }
}

class ViewDaylightIntentHandler: NSObject, ViewDaylightIntentHandling {
  func handle(intent: ViewDaylightIntent, completion: @escaping (ViewDaylightIntentResponse) -> Void) {
    if let date = intent.date?.date! {
      let solarCalculator = SolarCalculator(baseDate: date)
      let duration = solarCalculator.today.duration
      
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      
      let string = "\(duration.colloquialTimeString) of daylight on \(formatter.string(from: date))"
      completion(ViewDaylightIntentResponse.success(result: string))
    } else {
      completion(ViewDaylightIntentResponse.failure(error: "Unable to calculate daylight; the date provided may be invalid."))
    }
  }
  
  func resolveDate(for intent: ViewDaylightIntent, with completion: @escaping (ViewDaylightDateResolutionResult) -> Void) {
    if let date = intent.date {
      completion(ViewDaylightDateResolutionResult.success(with: date))
    } else {
      completion(ViewDaylightDateResolutionResult.unsupported(forReason: .invalidDate))
    }
  }
}

class ViewRemainingDaylightIntentHandler: NSObject, ViewRemainingDaylightIntentHandling {
  func handle(intent: ViewRemainingDaylightIntent, completion: @escaping (ViewRemainingDaylightIntentResponse) -> Void) {
    let calculator = SolarCalculator()
    let isDaytime = calculator.today.begins.isInPast && calculator.today.ends.isInFuture
    
    let relativeFormatter = RelativeDateTimeFormatter()
    let now = Date()
    
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    
    var result: String?
    
    if isDaytime {
      result = "There’s \(now.distance(to: calculator.today.ends).colloquialTimeString) of daylight left today. The sun sets at \(formatter.string(from: calculator.today.ends))."
    } else if calculator.today.ends.isInPast {
      result = "No more daylight today. The sun set \(relativeFormatter.localizedString(for: calculator.today.ends, relativeTo: now)) and rises again \(relativeFormatter.localizedString(for: calculator.tomorrow.begins, relativeTo: now))."
    } else if calculator.today.begins.isInFuture {
      result = "\(calculator.today.duration.colloquialTimeString) of daylight today. The sun rises \(relativeFormatter.localizedString(for: calculator.today.begins, relativeTo: now))."
    }
    
    if let result = result {
      completion(ViewRemainingDaylightIntentResponse.success(daylight: result))
    } else {
      completion(ViewRemainingDaylightIntentResponse.failure(error: "There was a problem calculating today’s remaining daylight. Open Solstice to see the latest information."))
    }
  }
}
