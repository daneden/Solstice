//
//  IntentHandler.swift
//  SolsticeIntents
//
//  Created by Daniel Eden on 11/04/2021.
//

import Intents
import Solar

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

class GetSunriseTimeIntentHandler: NSObject, GetSunriseTimeIntentHandling {
  func resolveDate(for intent: GetSunriseTimeIntent) async -> INDateComponentsResolutionResult {
    if let date = intent.date {
      return .success(with: date)
    } else {
      return .unsupported()
    }
  }
  
  func resolveLocation(for intent: GetSunriseTimeIntent) async -> INPlacemarkResolutionResult {
    if let location = intent.location {
      return location.location == nil ? .disambiguation(with: [location]) : .success(with: location)
    } else {
      return .unsupported()
    }
  }
  
  func handle(intent: GetSunriseTimeIntent) async -> GetSunriseTimeIntentResponse {
    if let dateComponents = intent.date,
       let date = dateComponents.date,
       let placemark = intent.location,
       let location = placemark.location?.coordinate {
      let solar = Solar(for: date, coordinate: location)
      
      if let sunriseTime = solar?.sunrise {
        return .success(sunriseTime: Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: sunriseTime), date: dateComponents, location: placemark)
      } else {
        return GetSunriseTimeIntentResponse(code: .failure, userActivity: nil)
      }
    } else {
      return GetSunriseTimeIntentResponse(code: .failure, userActivity: nil)
    }
  }
}

class GetSunsetTimeIntentHandler: NSObject, GetSunsetTimeIntentHandling {
  func resolveDate(for intent: GetSunsetTimeIntent) async -> INDateComponentsResolutionResult {
    if let date = intent.date {
      return .success(with: date)
    } else {
      return .unsupported()
    }
  }
  
  func resolveLocation(for intent: GetSunsetTimeIntent) async -> INPlacemarkResolutionResult {
    if let location = intent.location {
      return .success(with: location)
    } else {
      return .unsupported()
    }
  }
  
  func handle(intent: GetSunsetTimeIntent) async -> GetSunsetTimeIntentResponse {
    if let dateComponents = intent.date,
       let date = dateComponents.date,
       let placemark = intent.location,
       let location = placemark.location?.coordinate {
      let solar = Solar(for: date, coordinate: location)
      
      if let sunsetTime = solar?.sunset {
        return .success(sunsetTime: Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: sunsetTime), date: dateComponents, location: placemark)
      } else {
        return GetSunsetTimeIntentResponse(code: .failure, userActivity: nil)
      }
    } else {
      return GetSunsetTimeIntentResponse(code: .failure, userActivity: nil)
    }
  }
}
