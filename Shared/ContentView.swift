//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import Combine
import CoreLocation

struct ContentView: View {
  @ObservedObject var locationManager = LocationManager.shared
  
  var solarToday: Solar? {
    guard let coord =
            locationManager.location?.coordinate,
            CLLocationCoordinate2DIsValid(coord) else { return nil }
    return Solar(coordinate: coord)
  }
  
  var solarYesterday: Solar? {
    guard let coord =
            locationManager.location?.coordinate,
          CLLocationCoordinate2DIsValid(coord) else { return nil }
    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return nil }
    
    return Solar(for: yesterday, coordinate: coord)
  }
  
  var body: some View {
    if let sunsetToday = solarToday?.sunset,
       let sunsetYesterday = solarYesterday?.sunset {
      Text(sunsetToday, style: .time)
      Text(sunsetYesterday, style: .time)
      Text(locationManager.location?.coordinate.latitude.description ?? "0")
      Text(Date(), style: .time)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
