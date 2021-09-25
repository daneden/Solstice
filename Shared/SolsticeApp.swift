//
//  SolsticeApp.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI

@main
struct SolsticeApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @ObservedObject var locationManager = LocationManager.shared
  
  var body: some Scene {
    WindowGroup {
      Group {
        if locationManager.status == .authorizedAlways || locationManager.status == .authorizedWhenInUse {
          ContentView()
            .environmentObject(locationManager)
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
      .onDisappear {
        (UIApplication.shared.delegate as! AppDelegate).submitBackgroundTask()
      }
      .navigationViewStyle(StackNavigationViewStyle())
      .symbolRenderingMode(.hierarchical)
    }
  }
}
