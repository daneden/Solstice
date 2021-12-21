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
  
  @State var showingRemaining = false
  
  var body: some View {
    Group {
      if !isWatch, let placeName = getPlaceName() {
        Button(action: {
          self.activeSheet = .location
        }) {
          Label(placeName, systemImage: "location.fill")
            .foregroundColor(.accentColor)
        }
      }
      
      // MARK: Duration
      if let duration = calculator.today.duration {
        AdaptiveStack {
          if showingRemaining && calculator.today.ends.isInFuture && calculator.today.begins.isInPast {
            Label("Remaining", systemImage: "hourglass")
              .symbolRenderingMode(.monochrome)
            Spacer()
            Text(calculator.today.ends, style: .relative)
              .monospacedDigit()
          } else {
            Label("Total Daylight", systemImage: "sun.max")
            Spacer()
            Text("\(duration.localizedString)")
          }
        }.onTapGesture {
          withAnimation(.interactiveSpring()) {
            showingRemaining.toggle()
          }
        }
      }
      
      // MARK: Sunrise, culmination, and sunset times
      if let begins = calculator.today.begins,
         let peak = calculator.today.peak,
         let ends = calculator.today.ends {
        AdaptiveStack {
          Label("Sunrise", systemImage: "sunrise.fill")
          Spacer()
          Text("\(begins, style: .time)")
        }
        
        AdaptiveStack {
          Label("Culmination", systemImage: "sun.max.fill")
          Spacer()
          Text("\(peak, style: .time)")
        }
        
        AdaptiveStack {
          Label("Sunset", systemImage: "sunset.fill")
          Spacer()
          Text("\(ends, style: .time)")
        }
      }
    }
  }
  
  func getPlaceName() -> String {
    let sublocality = location.placemark?.subLocality
    let locality = location.placemark?.locality
    
    let builtString = [sublocality, locality]
      .compactMap { $0 }
      .joined(separator: ", ")
    
    return builtString.count == 0 ? "Current Location" : builtString
  }
}

struct AdaptiveStack<Content: View>: View {
  var content: () -> Content
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    if isWatch {
      VStack(alignment: .leading) {
        content()
      }
    } else {
      HStack {
        content()
      }
    }
  }
}

struct SolsticeOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeOverview(activeSheet: .constant(nil))
  }
}
