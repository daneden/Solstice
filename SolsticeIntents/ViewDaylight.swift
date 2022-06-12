//
//  ViewDaylight.swift
//  Solstice
//
//  Created by Daniel Eden on 12/06/2022.
//

import Foundation
import AppIntents
import CoreLocation
import Solar

struct ViewDaylight: AppIntent, CustomIntentMigratedAppIntent {
    static _const let intentClassName = "ViewDaylightIntent"
    
    static var title: LocalizedStringResource = "View Daylight"
    static var description = IntentDescription("View how much daylight there is on a given day, based on the duration from that day’s sunrise to sunset.")

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Location")
    var location: CLPlacemark?

    static var parameterSummary: some ParameterSummary {
      Summary("Get the daylight duration on \(\.$date) in \(\.$location)")
    }
    
    func perform() async throws -> some PerformResult {
      guard let date else {
        throw $date.requestValue("What date do you want to see the daylight for?")
      }
      
      guard let location,
            let coordinate = location.location?.coordinate else {
        throw $location.requestValue("What location do you want to see the daylight for?")
      }
      
      let solar = Solar(for: date, coordinate: coordinate)
      
      guard let sunrise = solar?.sunrise,
            let sunset = solar?.sunset else {
        return .finished(value: TimeInterval(0), dialog: "Unable to calculate daylight; the date provided may be invalid.")
      }
      
      let duration = sunrise.distance(to: sunset)
      
      return .finished(value: duration)
    }
}

