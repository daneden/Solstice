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
		// MARK: Duration
		let begins = calculator.today.begins
		let ends = calculator.today.ends
		let duration = calculator.today.duration
		Group {
			if showingRemaining && ends.isInFuture && begins.isInPast {
				LabeledContent {
					Text(ends, style: .relative)
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
		
		// MARK: Sunrise, culmination, and sunset times
		if let peak = calculator.today.peak {
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

struct SolsticeOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeOverview()
      .environmentObject(SheetPresentationManager())
  }
}
