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
  @ObservedObject var locationManager = LocationManager.shared
  
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
        if !locationManager.locationAvailable && !onboarding && locationManager.status != .some(.notDetermined) {
          sheetPresentation.activeSheet = .location
        }
      }
      .onChange(of: scenePhase) { _ in
        locationManager.updateLocationType()
        
        if scenePhase == .active {
          NotificationManager.shared.removeDeliveredNotifications()
          NotificationManager.shared.removePendingNotificationRequests()
        }
        
        // Always reschedule notifications
        // Since this function runs on the background thread and also doesn’t
        // schedule identical notifications, this is safe to run on all
        // scenePhase changes
        NotificationManager.shared.rescheduleNotifications()
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
