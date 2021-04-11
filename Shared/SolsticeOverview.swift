//
//  SolsticeOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct SolsticeOverview: View {
  @ObservedObject var calculator = SolarCalculator.shared
  @ObservedObject var location = LocationManager.shared
  @Binding var activeSheet: SheetPresentationState?
  
  var body: some View {
    VStack(alignment: .leading) {
      if let placeName = getPlaceName() {
        Button(action: {
          self.activeSheet = .location
        }) {
        Label(placeName, systemImage: "location.fill")
          .font(Font.subheadline.bold())
        }
        .buttonStyle(SecondaryButtonStyle())
      }
      
      Text("\(calculator.differenceString) daylight today than yesterday.")
        .lineLimit(4)
        .font(.largeTitle)
        .padding(.vertical).fixedSize(horizontal: false, vertical: true)
      
      // MARK: Metadata
      VStack(alignment: .leading, spacing: 12) {
        // MARK: Sunrise
        Divider()
        if let begins = calculator.today.begins {
          HStack {
            Label("Sunrise", systemImage: "sunrise.fill")
            Spacer()
            Text("\(begins, style: .time)")
          }
        }
        
        // MARK: Sunset
        Divider()
        if let ends = calculator.today.ends {
          HStack {
            Label("Sunset", systemImage: "sunset.fill")
            Spacer()
            Text("\(ends, style: .time)")
          }
        }
        
        // MARK: Duration
        Divider()
        if let duration = calculator.today.duration {
          HStack {
            Label("Total Daylight", systemImage: "sun.max")
            Spacer()
            Text("\(duration.colloquialTimeString)")
          }
        }
        
        if calculator.today.ends.isInFuture && calculator.today.begins.isInPast {
          HStack {
            Text("Total Remaining")
            Spacer()
            Text("\(Date().distance(to: calculator.today.ends).colloquialTimeString)")
          }.font(.footnote).foregroundColor(.secondary)
        }
      }
    }
  }
  
  func getPlaceName() -> String {
    let sublocality = location.placemark?.subLocality
    let locality = location.placemark?.locality
    
    let filtered = [sublocality, locality].filter { $0 != nil } as! [String]
    let builtString = filtered.joined(separator: ", ")
    
    return builtString.count == 0 ? "Current Location" : builtString
  }
}

struct SolsticeOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeOverview(activeSheet: .constant(nil))
  }
}
