//
//  SolsticeApp.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import StoreKit

enum SheetPresentationState: Identifiable {
  case settings, location
  
  var id: Int {
    hashValue
  }
}

@main
struct SolsticeApp: App {
  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif
  
  @AppStorage(UDValues.locations) var locations
  
  @State private var activeSheet: SheetPresentationState?
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        List {
          NavigationLink(destination: MainView().navigationTitle("Current Location")) {
            Label("Current Location", systemImage: "location")
          }
          
          
          Section(header: Text("Saved Locations")) {
            Button(action: {
              self.activeSheet = .location
            }) {
              Label("Add Location", systemImage: "plus.circle")
            }
            
            if !locations.isEmpty {
              ForEach(Array(locations), id: \.id) { location in
                NavigationLink(
                  destination: MainView(locationManager: locationManager(for: location))
                    .navigationBarTitle(location.name)
                ) {
                  Text(location.name)
                }
              }.onDelete(perform: deleteLocations)
            }
          }
        }
        .navigationTitle("Solstice")
        #if !os(watchOS)
        .toolbar {
          Button(action: { self.activeSheet = .settings }) {
            Label("Settings", systemImage: "gearshape")
          }
        }
        .sheet(item: $activeSheet) { item in
          switch item {
          case .settings:
            SettingsView()
          case .location:
            LocationPickerView(onSelection: { location in
              if let location = location {
                locations.insert(location)
              }
            })
              .environmentObject(LocationManager())
              .environmentObject(LocationService())
          }
        }
        #endif
        
        MainView()
      }
      #if !os(watchOS)
      .onDisappear {
        (UIApplication.shared.delegate as! AppDelegate).submitBackgroundTask()
      }
      #endif
      .symbolRenderingMode(.hierarchical)
    }
  }
  
  func locationManager(for location: Location) -> LocationManager {
    let locationManager = LocationManager()
    locationManager.manuallySetLocation(to: .init(latitude: location.latitude, longitude: location.longitude))
    
    return locationManager
  }
  
  func deleteLocations(at offsets: IndexSet) {
    let locationsAsArray = Array(locations)
    
    for offset in offsets {
      locations.remove(locationsAsArray[offset])
    }
  }
}
