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
  @EnvironmentObject var calculator: SolarCalculator
  @EnvironmentObject var location: LocationManager
  
  var displaySize: Font {
    switch family {
    case .systemSmall:
      return .headline
    default:
      return .title2
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if case .sunset(let date) = nextSunEvent {
        Image(systemName: "sun.max.fill")
          .font(displaySize)
        Spacer()
        Text("\(date, style: .relative) until sunset")
          .font(displaySize.weight(.medium))
          .lineLimit(3)
        
        Text("\(date, style: .time)")
          .font(.footnote)
      } else if case .sunrise(let date) = nextSunEvent {
        Image(systemName: "moon.stars.fill")
          .font(displaySize)
        Spacer()
        Text("\(date, style: .relative) until sunrise")
          .font(displaySize.weight(.medium))
          .lineLimit(3)
        
        Text("\(date, style: .time)")
          .font(.footnote)
      }
    }
    .foregroundColor(isDaytime ? .orange : .indigo)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(isDaytime ? Color.yellow.opacity(0.2) : Color.indigo.opacity(0.1))
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
