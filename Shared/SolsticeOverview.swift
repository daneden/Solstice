//
//  SolsticeOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct SolsticeOverview: View {
  @EnvironmentObject var calculator: SolarCalculator
  @EnvironmentObject var location: LocationManager
  @EnvironmentObject var sheetPresentation: SheetPresentationManager
  
  @State private var showingRemaining = false
  
  var locationButtonImageName: String {
    switch location.locationType {
    case .real(let status) where status.isAuthorized:
      return "location.fill"
    default:
      return "location"
    }
  }
  
  var body: some View {
    Group {
      if !isWatch, let placeName = getPlaceName() {
        Button(action: {
          self.sheetPresentation.activeSheet = .location
        }) {
          Label(placeName, systemImage: locationButtonImageName)
            .foregroundColor(.accentColor)
        }
      }
      
      // MARK: Duration
      if let duration = calculator.today.duration {
        Group {
          if showingRemaining && calculator.today.ends.isInFuture && calculator.today.begins.isInPast {
            LabeledContent {
              Text(calculator.today.ends, style: .relative)
                .monospacedDigit()
            } label: {
              Label("Remaining", systemImage: "hourglass")
            }
          } else {
            LabeledContent {
              Text("\(duration.localizedString)")
            } label: {
              Label("Total Daylight", systemImage: "sun.max")
            }
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
        LabeledContent {
          Text("\(begins, style: .time)")
        } label: {
          Label("Sunrise", systemImage: "sunrise.fill")
        }
        
        LabeledContent {
          Text("\(peak, style: .time)")
        } label: {
          Label("Culmination", systemImage: "sun.max.fill")
        }
        
        LabeledContent {
          Text("\(ends, style: .time)")
        } label: {
          Label("Sunset", systemImage: "sunset.fill")
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

struct SolsticeOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeOverview()
      .environmentObject(SheetPresentationManager())
  }
}
