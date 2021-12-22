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
  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var locationService = LocationService()
  #endif
  @ObservedObject var locationManager = LocationManager()
  
  @AppStorage(UDValues.onboarding) var onboarding
  @State var placeholder = false
  @State var sheet: SheetPresentationState?
  
  var body: some Scene {
    WindowGroup {
      Group {
        if placeholder {
          ContentView(activeSheet: sheet)
            .redacted(reason: .placeholder)
        } else {
          ContentView(activeSheet: sheet)
        }
      }
      .onAppear {
        locationManager.start()
      }
      .fullScreenCover(isPresented: $onboarding) {
        LandingView()
      }
      .onChange(of: onboarding) { newValue in
        placeholder = onboarding
        
        if !locationManager.locationAvailable && !onboarding {
          sheet = .location
        }
      }
      .onChange(of: scenePhase) { _ in
        locationManager.updateLocationType()
      }
      .environmentObject(locationManager)
      .environmentObject(SolarCalculator(locationManager: locationManager))
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
