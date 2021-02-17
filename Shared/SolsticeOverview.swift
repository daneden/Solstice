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
  @State var locationPickerOpen = false
  
  var body: some View {
    VStack(alignment: .leading) {
      if let placeName = getPlaceName() {
        Button(action: {
          self.locationPickerOpen.toggle()
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
      
      HStack {
        VStack(alignment: .leading) {
          Label("Sunrise", systemImage: "sunrise.fill")
          if let begins = calculator.today.begins,
             let beginsYesterday = calculator.yesterday.begins {
            Text("\(begins, style: .time)")
            
            VStack(alignment: .leading) {
              Text("Yesterday")
              Text("\(beginsYesterday, style: .time)")
            }.foregroundColor(.secondary).font(Font.footnote.monospacedDigit()).padding(.top, 4)
          }
        }
        
        Spacer()
        
        VStack(alignment: .trailing) {
          Label("Sunset", systemImage: "sunset.fill")
          if let ends = calculator.today.ends,
             let endsYesterday = calculator.yesterday.ends {
            Text("\(ends, style: .time)")
            
            VStack(alignment: .trailing) {
              Text("Yesterday")
              Text("\(endsYesterday, style: .time)")
            }.foregroundColor(.secondary).font(Font.footnote.monospacedDigit()).padding(.top, 4)
          }
        }
      }.font(Font.body.monospacedDigit())
    }
    .sheet(isPresented: $locationPickerOpen) {
      LocationPickerView()
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
    SolsticeOverview()
  }
}
