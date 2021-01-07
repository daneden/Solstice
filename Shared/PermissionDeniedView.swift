//
//  PermissionDeniedView.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct PermissionDeniedView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Solstice needs access to your location to work properly.")
        .font(Font.system(.largeTitle, design: .rounded).bold())
      Text("Location access has been denied or revoked. To use Solstice, go to the Settings app and grant Solstice permission to access your location.")
    }
  }
}

struct PermissionDeniedView_Previews: PreviewProvider {
  static var previews: some View {
    PermissionDeniedView()
  }
}
