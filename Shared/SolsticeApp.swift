//
//  SolsticeApp.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI

@main
struct SolsticeApp: App {
  @ObservedObject var locationManager = LocationManager.shared
  var body: some Scene {
    WindowGroup {
      NavigationView {
        if locationManager.status == .authorizedAlways || locationManager.status == .authorizedWhenInUse {
          ContentView()
            .environmentObject(locationManager)
            .onAppear {
              locationManager.start()
            }
        } else if locationManager.status == .notDetermined {
          LandingView()
        } else {
          PermissionDeniedView()
        }
      }.accentColor(.systemOrange)
    }
  }
}
