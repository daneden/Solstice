//
//  SolsticeCountdownWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 11/04/2021.
//

import SwiftUI

enum SunEvent {
  case sunrise(at: Date)
  case sunset(at: Date)
}

struct SolsticeCountdownWidgetView: View {
  @Environment(\.widgetFamily) var family
  var calculator = SolarCalculator()
  @ObservedObject var location = LocationManager.shared
  
  var displaySize: Font {
    switch family {
    case .systemSmall:
      return .headline
    default:
      return .title
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if case .sunset(let date) = nextSunEvent {
        Image(systemName: "sun.max.fill")
          .font(displaySize)
        Spacer()
        Text("\(date, style: .relative) until sunset")
          .font(displaySize)
          .lineLimit(nil)
        
        Text("\(date, style: .time)")
          .font(.footnote)
      } else if case .sunrise(let date) = nextSunEvent {
        Image(systemName: "moon.stars.fill")
          .font(displaySize)
        Spacer()
        Text("\(date, style: .relative) until sunrise")
          .font(displaySize)
          .lineLimit(nil)
        
        Text("\(date, style: .time)")
          .font(.footnote)
      }
    }
    .foregroundColor(isDaytime ? Color.systemOrange : Color.systemIndigo)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(isDaytime ? Color.systemYellow.opacity(0.2) : Color.systemIndigo.opacity(0.1))
    .colorScheme(isDaytime ? .light : .dark)
  }
  
  var isDaytime: Bool {
    calculator.today.begins.isInPast && calculator.today.ends.isInFuture
  }
  
  var nextSunEvent: SunEvent {
    if isDaytime {
      return .sunset(at: calculator.today.ends)
    } else if calculator.today.begins.isInFuture {
      return .sunrise(at: calculator.today.begins)
    } else {
      return .sunrise(at: calculator.tomorrow.begins)
    }
  }
}

struct SolsticeCountdownWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SolsticeCountdownWidgetView()
    }
}
