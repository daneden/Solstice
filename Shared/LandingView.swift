//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct LandingView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Image(systemName: "sunrise.fill")
        .font(Font.system(.largeTitle, design: .rounded).bold())
        .padding(.bottom)
      
      Text("Solstice tells you how much daylight there is today compared to yesterday.")
        .font(Font.system(.largeTitle, design: .rounded).bold())
      
      Text("For savouring the minutes you have, or looking forward to the minutes you'll gain.")
        .padding(.vertical)
      
      Text("In order for Solstice to calculate the sun’s position, it needs to access your location.")
        .padding(.bottom)
      
      Button(action: { LocationManager.shared.requestAuthorization() }) {
        Label("Grant permission access", systemImage: "location.fill")
          .frame(maxWidth: .infinity)
          .font(Font.subheadline.bold())
          .foregroundColor(.primary)
          .colorInvert()
          .padding()
      }.background(
        Capsule().fill(Color.primary)
      )
    }.padding()
  }
}

struct LandingView_Previews: PreviewProvider {
  static var previews: some View {
    LandingView()
  }
}
