//
//  SolsticeApp.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import StoreKit

@main
struct SolsticeApp: App {
  @ObservedObject var locationManager = LocationManager()
  
  var body: some Scene {
    WindowGroup {
      Group {
        if let status = locationManager.status, status.isAuthorized {
          ContentView()
        } else {
          PermissionRequiredView()
        }
      }
      .onAppear {
        locationManager.requestAuthorization()
        locationManager.start()
      }
      .environmentObject(locationManager)
      .environmentObject(SolarCalculator(locationManager: locationManager))
      .navigationViewStyle(StackNavigationViewStyle())
      .symbolRenderingMode(.hierarchical)
    }
  }
}
