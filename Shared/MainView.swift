//
//  MainView.swift
//  Solstice
//
//  Created by Daniel Eden on 21/12/2021.
//

import SwiftUI

struct MainView: View {
  @ObservedObject var locationManager = LocationManager()
  
  var body: some View {
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
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView()
  }
}
