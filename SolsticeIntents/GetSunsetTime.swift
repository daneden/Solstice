//
//  GetSunsetTime.swift
//  Solstice
//
//  Created by Daniel Eden on 12/06/2022.
//

import Foundation
import AppIntents
import CoreLocation
import Solar

struct GetSunsetTime: AppIntent, CustomIntentMigratedAppIntent {
    static _const let intentClassName = "GetSunsetTimeIntent"
    
    static var title: LocalizedStringResource = "Get Sunset Time"
    static var description = IntentDescription("Calculate the sunset time on a given date in a given location")

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Location")
    var location: CLPlacemark?

    static var parameterSummary: some ParameterSummary {
      Summary("Get the sunset time on \(\.$date) in \(\.$location)")
    }
    
    func perform() async throws -> some PerformResult {
      guard let date else {
        throw $date.requestValue("What date do you want to see the sunset for?")
      }
      
      guard let location,
            let coordinate = location.location?.coordinate else {
        throw $location.requestValue("What location do you want to see the sunset for?")
      }
      
      let solar = Solar(for: date, coordinate: coordinate)
      
      guard let sunset = solar?.sunset else {
        return .finished(value: Date(), dialog: "Unable to calculate sunset time; the date provided may be invalid.")
      }
      
      return .finished(value: sunset)
    }
}

