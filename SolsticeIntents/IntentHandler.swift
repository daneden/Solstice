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
    case is GetSunsetTimeIntent:
      return GetSunsetTimeIntentHandler()
    case is GetSunriseTimeIntent:
      return GetSunriseTimeIntentHandler()
    default:
      return self
    }
  }
}

class ViewDaylightIntentHandler: NSObject, ViewDaylightIntentHandling {
  func handle(intent: ViewDaylightIntent) async -> ViewDaylightIntentResponse {
    if let date = intent.date?.date,
       let placemark = intent.location,
       let location = placemark.location?.coordinate {
      let solar = Solar(for: date, coordinate: location)
      
      guard let sunrise = solar?.sunrise, let sunset = solar?.sunset else {
        return .failure(error: "Unable to calculate daylight; the date provided may be invalid.")
      }
      
      let duration = sunrise.distance(to: sunset)
      
      return .success(
        result: NSNumber(value: duration),
        date: Calendar.autoupdatingCurrent.dateComponents(Set(Calendar.Component.allCases), from: date),
        location: placemark
      )
    } else {
      return .failure(error: "Unable to calculate daylight; the date provided may be invalid.")
    }
  }
  
  func resolveDate(for intent: ViewDaylightIntent) async -> ViewDaylightDateResolutionResult {
    if let date = intent.date {
      return .success(with: date)
    } else {
      return .needsValue()
    }
  }
  
  func resolveLocation(for intent: ViewDaylightIntent) async -> INPlacemarkResolutionResult {
    if let location = intent.location {
      return .success(with: location)
    } else {
      return .needsValue()
    }
  }
}

class ViewRemainingDaylightIntentHandler: NSObject, ViewRemainingDaylightIntentHandling {
  func handle(intent: ViewRemainingDaylightIntent) async -> ViewRemainingDaylightIntentResponse {
    let calculator = SolarCalculator()
    let isDaytime = calculator.today.begins.isInPast && calculator.today.ends.isInFuture
    
    if isDaytime {
      return .success(
        result: NSNumber(value: Date().distance(to: calculator.today.ends))
      )
    } else if calculator.today.ends.isInPast {
      return .noDaylightRemaining(
        nextSunriseTime: Calendar.autoupdatingCurrent.dateComponents(Set(Calendar.Component.allCases), from: calculator.tomorrow.begins)
      )
    } else if calculator.today.begins.isInFuture {
      return .success(result: NSNumber(value: calculator.today.duration))
    } else {
      return .failure(error: "Something went wrong")
    }
  }
}

class GetSunriseTimeIntentHandler: NSObject, GetSunriseTimeIntentHandling {
  private let calendar = Calendar.autoupdatingCurrent
  
  func resolveDate(for intent: GetSunriseTimeIntent) async -> INDateComponentsResolutionResult {
    if let date = intent.date {
      return .success(with: date)
    } else {
      return .needsValue()
    }
  }
  
  func resolveLocation(for intent: GetSunriseTimeIntent) async -> INPlacemarkResolutionResult {
    if let location = intent.location {
      return .success(with: location)
    } else {
      return .needsValue()
    }
  }
  
  func handle(intent: GetSunriseTimeIntent) async -> GetSunriseTimeIntentResponse {
    if let dateComponents = intent.date,
       let date = dateComponents.date,
       let placemark = intent.location,
       let location = placemark.location?.coordinate {
      let resultDateComponents = calendar.dateComponents([.day, .month, .year], from: date)
      let solar = Solar(for: date, coordinate: location)
      
      if let sunriseTime = solar?.sunrise {
        return .success(
          sunriseTime: calendar.dateComponents(Set(Calendar.Component.allCases), from: sunriseTime),
          date: resultDateComponents,
          location: placemark
        )
      } else {
        return GetSunriseTimeIntentResponse(code: .failure, userActivity: nil)
      }
    } else {
      return GetSunriseTimeIntentResponse(code: .failure, userActivity: nil)
    }
  }
}

class GetSunsetTimeIntentHandler: NSObject, GetSunsetTimeIntentHandling {
  private let calendar = Calendar.autoupdatingCurrent
  func resolveDate(for intent: GetSunsetTimeIntent) async -> INDateComponentsResolutionResult {
    if let date = intent.date {
      return .success(with: date)
    } else {
      return .needsValue()
    }
  }
  
  func resolveLocation(for intent: GetSunsetTimeIntent) async -> INPlacemarkResolutionResult {
    if let location = intent.location {
      return .success(with: location)
    } else {
      return .needsValue()
    }
  }
  
  func handle(intent: GetSunsetTimeIntent) async -> GetSunsetTimeIntentResponse {
    if let dateComponents = intent.date,
       let date = dateComponents.date,
       let placemark = intent.location,
       let location = placemark.location?.coordinate {
      let resultDateComponents = calendar.dateComponents([.day, .month, .year], from: date)
      let solar = Solar(for: date, coordinate: location)
      
      if let sunsetTime = solar?.sunset {
        return .success(
          sunsetTime: calendar.dateComponents(Set(Calendar.Component.allCases), from: sunsetTime),
          date: resultDateComponents,
          location: placemark
        )
      } else {
        return GetSunsetTimeIntentResponse(code: .failure, userActivity: nil)
      }
    } else {
      return GetSunsetTimeIntentResponse(code: .failure, userActivity: nil)
    }
  }
}
