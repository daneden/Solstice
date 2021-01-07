//
//  SolsticeOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct SolsticeOverview: View {
  var calculator = SolarCalculator()
  @ObservedObject var location = LocationManager.shared
  
  var body: some View {
    VStack(alignment: .leading) {
      if let location = location.placemark?.locality ?? "Current Location" {
        Label(location, systemImage: "location.fill")
          .font(Font.subheadline.bold())
          .foregroundColor(.secondary)
      }
      
      Text("\(calculator.differenceString) \(verbiage) daylight today than yesterday.")
        .lineLimit(4)
        .font(Font.system(.largeTitle, design: .rounded).bold())
        .padding(.vertical).fixedSize(horizontal: false, vertical: true)
      
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Yesterday").font(.caption)
            Spacer()
          }
          if let ends = calculator.yesterday?.ends,
             let begins = calculator.yesterday?.begins {
            Label("\(begins, style: .time)", systemImage: "sunrise")
            Label("\(ends, style: .time)", systemImage: "sunset")
          }
        }.foregroundColor(.secondary)
        
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Today").font(.caption)
            Spacer()
          }
          if let ends = calculator.today?.ends,
             let begins = calculator.today?.begins {
            Label("\(begins, style: .time)", systemImage: "sunrise.fill")
            Label("\(ends, style: .time)", systemImage: "sunset.fill")
          }
        }
        
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Tomorrow").font(.caption)
            Spacer()
          }
          if let ends = calculator.tomorrow?.ends,
             let begins = calculator.tomorrow?.begins {
            Label("\(begins, style: .time)", systemImage: "sunrise")
            Label("\(ends, style: .time)", systemImage: "sunset")
          }
        }.foregroundColor(.secondary)
      }.font(.system(.footnote, design: Font.Design.monospaced))
    }
  }
  
  var verbiage: String {
    calculator.difference.minutes >= 0 && calculator.difference.seconds >= 0
      ? "more" : "less"
  }
}

struct SolsticeOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeOverview()
  }
}
