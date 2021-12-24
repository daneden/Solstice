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
  @Environment(\.scenePhase) var scenePhase
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var locationService = LocationService()
  @ObservedObject var locationManager = LocationManager()
  
  @AppStorage(UDValues.onboarding) var onboarding
  @StateObject var sheetPresentation = SheetPresentationManager()
  
  var body: some Scene {
    WindowGroup {
      Group {
        if onboarding {
          ProgressView()
        } else {
          ContentView()
            .environmentObject(sheetPresentation)
        }
      }
      .onAppear {
        if let status = locationManager.status, status.isAuthorized {
          onboarding = false
        }
        
        locationManager.start()
      }
      .fullScreenCover(isPresented: $onboarding) {
        LandingView()
      }
      .onChange(of: onboarding) { newValue in
        if !locationManager.locationAvailable && !onboarding {
          sheetPresentation.activeSheet = .location
        }
      }
      .onChange(of: scenePhase) { _ in
        locationManager.updateLocationType()
        
        if scenePhase == .active {
          NotificationManager.shared.removeDeliveredNotifications()
        } else {
          NotificationManager.shared.rescheduleNotifications()
        }
      }
      .environmentObject(locationManager)
      .environmentObject(SolarCalculator(locationManager: locationManager))
      .onDisappear {
        (UIApplication.shared.delegate as! AppDelegate).submitBackgroundTask()
      }
      .environmentObject(locationService)
      .navigationViewStyle(StackNavigationViewStyle())
      .symbolRenderingMode(.hierarchical)
    }
  }
}
