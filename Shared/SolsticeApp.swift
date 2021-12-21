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
  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var locationService = LocationService()
  #endif
  @ObservedObject var locationManager = LocationManager()
  
  var body: some Scene {
    WindowGroup {
      Group {
        if locationManager.locationAvailable {
          ContentView()
            .environmentObject(SolarCalculator(locationManager: locationManager))
            .onAppear {
              locationManager.start()
            }
        } else if locationManager.status == .notDetermined {
          VStack {
            LandingView()
              .frame(maxWidth: 500)
          }
        } else {
          VStack {
            PermissionDeniedView()
              .frame(maxWidth: 500)
          }
        }
      }
      .environmentObject(locationManager)
      #if os(iOS)
      .onDisappear {
        (UIApplication.shared.delegate as! AppDelegate).submitBackgroundTask()
      }
      .environmentObject(locationService)
      #endif
      .navigationViewStyle(StackNavigationViewStyle())
      .symbolRenderingMode(.hierarchical)
    }
  }
}
