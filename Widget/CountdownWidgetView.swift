//
//  SolsticeCountdownWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 11/04/2021.
//

import SwiftUI
import WidgetKit
import Solar

struct CountdownWidgetView: View {
  @Environment(\.widgetFamily) var family
  @Environment(\.sizeCategory) var sizeCategory
  var solar: Solar
  var nextSunEvent: SolarEvent
  
  var displaySize: Font {
    switch family {
    case .systemSmall:
      return sizeCategory < .extraLarge ? .headline : .footnote
    default:
      return .title2
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: currentEventImageName)
        .font(displaySize)
      
      Spacer(minLength: 0)
      
      HStack {
        Text("\(nextSunEvent.description.localizedCapitalized) \(nextSunEvent.date.formatted(.relative(presentation: .numeric)))")
          .font(displaySize.weight(.medium))
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
      }
      
      Label("\(nextSunEvent.date, style: .time)", systemImage: nextSunEvent.imageName)
        .font(.footnote.weight(.semibold))
    }
    .padding()
    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .center))
    .background(LinearGradient(colors: SkyGradient.getCurrentPalette(for: solar), startPoint: .top, endPoint: .bottom))
    .colorScheme(.dark)
    .symbolRenderingMode(.hierarchical)
    .symbolVariant(.fill)
  }
  
  var currentEventImageName: String {
    switch nextSunEvent {
    case .sunrise(_):
      return "moon.stars"
    case .sunset(_):
      return "sun.max"
    }
  }
}

struct SolsticeCountdownWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    let calc = SolarCalculator()
    
    return Group {
      CountdownWidgetView(solar: calc.today, nextSunEvent: calc.nextSunEvent)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
      CountdownWidgetView(solar: calc.today, nextSunEvent: calc.nextSunEvent)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
    .environmentObject(SolarCalculator())
  }
}
