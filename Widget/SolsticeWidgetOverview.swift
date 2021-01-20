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
        SundialView(calculator: calculator).padding(.horizontal, -20)
        Spacer()
      }
      
      Filler()
      
      Image("Solstice-Icon")
        .resizable()
        .frame(width: 16, height: 16)
      if let duration = calculator.today.duration.colloquialTimeString {
        Text("Daylight today:")
          .font(.caption)
        
        Text("\(duration)")
          .lineLimit(4)
          .font(Font.system(family == .systemSmall ? .footnote : .headline, design: .rounded).bold().leading(.tight))
          .fixedSize(horizontal: false, vertical: true)
      }
      
      Spacer()
        
      if family != .systemSmall {
        Text("\(calculator.differenceString) than yesterday.")
          .lineLimit(4)
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        
        Spacer()
        
        HStack {
          if let begins = calculator.today.begins {
            Label("\(begins, style: .time)", systemImage: "sunrise.fill")
          }
          
          Spacer()
          
          if let ends = calculator.today.ends {
            Label("\(ends, style: .time)", systemImage: "sunset.fill")
          }
        }.font(.caption)
      } else {
        Spacer()
        
        VStack(alignment: .leading) {
          if let begins = calculator.today.begins {
            Label("\(begins, style: .time)", systemImage: "sunrise.fill")
          }
          
          if let ends = calculator.today.ends {
            Label("\(ends, style: .time)", systemImage: "sunset.fill")
          }
        }.font(.caption).foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct SolsticeWidgetOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeWidgetOverview()
  }
}
