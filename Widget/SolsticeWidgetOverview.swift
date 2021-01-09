//
//  SolsticeOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct SolsticeWidgetOverview: View {
  @Environment(\.widgetFamily) var family
  var calculator = SolarCalculator()
  @ObservedObject var location = LocationManager.shared
  
  var body: some View {
    VStack(alignment: .leading) {
      if family == .systemLarge {
        SundialView().padding(.horizontal, -20)
        Spacer()
      }
      
      Image("Solstice-Icon")
        .resizable()
        .frame(width: 16, height: 16)
      if let hours = calculator.today?.durationComponents.hour,
         let minutes = calculator.today?.durationComponents.minute {
        Text("Daylight today:")
          .font(.caption)
        
        Text("\(hours)hrs, \(minutes)mins")
          .lineLimit(4)
          .font(Font.system(.headline, design: .rounded).bold())
          .fixedSize(horizontal: false, vertical: true)
      }
      
      Spacer()
      
      Text("\(calculator.differenceString) \(verbiage) than yesterday.")
        .lineLimit(4)
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        
      if family != .systemSmall {
        Spacer()
        
        HStack {
          if let begins = calculator.today?.begins {
            Label("\(begins, style: .time)", systemImage: "sunrise.fill")
          }
          
          Spacer()
          
          if let ends = calculator.today?.ends {
            Label("\(ends, style: .time)", systemImage: "sunset.fill")
          }
        }.font(.caption)
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  var verbiage: String {
    calculator.differenceComponents.minutes >= 0 && calculator.differenceComponents.seconds >= 0
      ? "more" : "less"
  }
}

struct SolsticeWidgetOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeWidgetOverview()
  }
}
