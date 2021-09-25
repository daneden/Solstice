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
    ZStack(alignment: .bottomLeading) {
      GeometryReader { geom in
        if family != .systemSmall {
          SundialView(sunSize: 16.0, trackWidth: 1.5)
            .padding(.horizontal, -20)
            .frame(maxHeight: 200)
          
          if family == .systemMedium {
            VStack {
              Spacer()
              Color.systemBackground
                .frame(width: geom.size.width / 2, height: geom.size.height / 1.25)
                .blur(radius: 20)
            }
          }
        }
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Image("Solstice-Icon")
          .resizable()
          .frame(width: 16, height: 16)
        
        Spacer()
        
        if let duration = calculator.today.duration.colloquialTimeString {
          Text("Daylight today:")
            .font(.caption)
          
          Text("\(duration)")
            .lineLimit(4)
            .font(Font.system(family == .systemSmall ? .footnote : .headline, design: .rounded).bold().leading(.tight))
            .fixedSize(horizontal: false, vertical: true)
        }
          
        if family != .systemSmall {
          Text("\(calculator.differenceString) than yesterday.")
            .lineLimit(4)
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          
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
          VStack(alignment: .leading) {
            if let begins = calculator.today.begins {
              Label("\(begins, style: .time)", systemImage: "sunrise.fill")
            }
            
            if let ends = calculator.today.ends {
              Label("\(ends, style: .time)", systemImage: "sunset.fill")
            }
          }.font(.caption).foregroundColor(.secondary)
        }
      }.symbolRenderingMode(.hierarchical).imageScale(.large)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct SolsticeWidgetOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeWidgetOverview()
  }
}
