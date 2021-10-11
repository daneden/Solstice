//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct LandingView: View {
  let iconSize: CGFloat = isWatch ? 24 : 48
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Image("Solstice-Icon")
          .resizable()
          .frame(width: iconSize, height: iconSize)
          .padding(.bottom)
        
        Text("Solstice tells you how much daylight there is today compared to yesterday.")
          .font(isWatch ? .headline : .largeTitle)
        
        Text("For savouring the minutes you have, or looking forward to the minutes you'll gain.")
          .padding(.vertical)
        
        Text("In order for Solstice to calculate the sun’s position, it needs to access your location.")
          .padding(.bottom)
        
        Button(action: { LocationManager.shared.requestAuthorization() }) {
          Label("Grant location access", systemImage: "location.fill")
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
}

struct LandingView_Previews: PreviewProvider {
  static var previews: some View {
    LandingView()
  }
}
