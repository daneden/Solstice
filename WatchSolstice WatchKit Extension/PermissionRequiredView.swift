//
//  PermissionRequiredView.swift
//  WatchSolstice WatchKit Extension
//
//  Created by Daniel Eden on 22/12/2021.
//

import SwiftUI

struct PermissionRequiredView: View {
    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Location Permission Required")
            .font(.headline)
          
          Text("Sosltice requires your location to calculate the sunrise/sunset times.")
          Text("Your location data is never used for any other purpose.")
          
          Text("Go to Settings → Privacy → Location Services to change the access settings for Solstice.")
        }.lineLimit(nil)
      }
    }
}

struct PermissionRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionRequiredView()
    }
}
