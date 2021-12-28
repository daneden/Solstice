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
  @AppStorage("sessionCount") var sessionCount = 0
  @ObservedObject var locationManager = LocationManager.shared
  @StateObject var sheetPresentation = SheetPresentationManager()
  
  var body: some Scene {
    WindowGroup {
      Group {
        if let status = locationManager.status, status.isAuthorized {
          ContentView()
            .environmentObject(sheetPresentation)
        } else {
          PermissionRequiredView()
        }
      }
      .onAppear {
        locationManager.requestAuthorization()
        locationManager.start()
        sessionCount += 1
      }
      .environmentObject(locationManager)
      .environmentObject(SolarCalculator(locationManager: locationManager))
      .navigationViewStyle(StackNavigationViewStyle())
      .symbolRenderingMode(.hierarchical)
    }
  }
}
