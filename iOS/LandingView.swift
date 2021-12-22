//
//  LandingView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct LandingViewGradient {
  static let dawn = [
    Color(red: 0.388, green: 0.435, blue: 0.643),
    Color(red: 0.91, green: 0.796, blue: 0.753)
  ]
  
  static let morning = [
    Color(red: 0.11, green: 0.573, blue: 0.824),
    Color(red: 0.949, green: 0.988, blue: 0.996)
  ]
  
  static let noon = [
    Color(red: 0.184, green: 0.502, blue: 0.929),
    Color(red: 0.337, green: 0.8, blue: 0.949)
  ]
  
  static let afternoon = [
    Color(red: 0, green: 0.353, blue: 0.655),
    Color(red: 1, green: 0.992, blue: 0.894)
  ]
  
  static let evening = [
    Color(red: 0.208, green: 0.361, blue: 0.49),
    Color(red: 0.424, green: 0.357, blue: 0.482),
    Color(red: 0.753, green: 0.424, blue: 0.518)
  ]
  
  static let night = [
    Color(red: 0.087, green: 0.176, blue: 0.221),
    Color(red: 0.034, green: 0.146, blue: 0.258)
  ]
  
  static var colors: [[Color]] {
    [dawn, morning, noon, afternoon, evening, night]
  }
  
  static func getCurrentPalette() -> [Color] {
    let timeAsIndex = Int(Double(Calendar.autoupdatingCurrent.component(.hour, from: .now) + 8) / 6) % colors.count
    return colors[timeAsIndex]
  }
}

struct LandingView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var locationManager: LocationManager
  let iconSize: CGFloat = isWatch ? 24 : 48
  
  var gradientStops: [Color] {
    LandingViewGradient.getCurrentPalette()
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
