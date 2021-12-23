//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct LandingView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var locationManager: LocationManager
  let iconSize: CGFloat = isWatch ? 24 : 48
  
  var gradientStops: [Color] {
    SkyGradient.getCurrentPalette()
  }
  
  var body: some View {
    ZStack {
      #if !os(watchOS)
      LinearGradient(
        colors: gradientStops,
        startPoint: .top,
        endPoint: .bottom
      ).edgesIgnoringSafeArea(.all)
      #endif
      
      GeometryReader { geometry in
        ScrollView {
          VStack(alignment: .leading) {
            Group {
              Image("Solstice-Icon")
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .padding(.bottom)
              
              Text("Solstice tells you how much daylight there is today compared to yesterday.")
                .font(isWatch ? .headline : .largeTitle)
                .fontWeight(.semibold)
              
              Text("For savouring the minutes you have, or looking forward to the minutes you'll gain.")
                .padding(.vertical)
              
              Text("In order for Solstice to calculate the sun’s position, it needs to access your location.")
                .padding(.bottom)
            }.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            
            Spacer()
            
            Group {
              Button(action: {
                locationManager.requestAuthorization() {
                  self.presentationMode.wrappedValue.dismiss()
                }
              }) {
                Label("Continue with location", systemImage: "location.fill")
                  .frame(maxWidth: .infinity)
                  .font(.headline)
                  .blendMode(.difference)
                  .padding(8)
              }.buttonStyle(.borderedProminent)
              
              #if !os(watchOS)
              Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Continue without location")
                  .frame(maxWidth: .infinity)
                  .font(.headline)
                  .padding(8)
                  .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
              }.buttonStyle(.bordered)
              #endif
            }.accentColor(.primary)
          }
          .padding()
          .frame(minHeight: geometry.size.height)
        }
      }
    }.preferredColorScheme(.dark)
  }
}

struct LandingView_Previews: PreviewProvider {
  static var previews: some View {
    LandingView()
      .environmentObject(LocationManager())
  }
}
