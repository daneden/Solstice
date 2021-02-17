//
//  SolarTimeMachine.swift
//  Solstice
//
//  Created by Daniel Eden on 19/01/2021.
//

import SwiftUI

struct SolarTimeMachine: View {
  @State var timeTravelVisible = false
  @Binding var dateOffset: Double
  @Binding var selectedDate: Date
  @ObservedObject var calculator: SolarCalculator = .shared
  
  var waveSize = UIScreen.screenHeight * 0.1
  
  var body: some View {
    VStack {
      Button(action: {
        withAnimation(stiffSpringAnimation) {
          if timeTravelVisible {
            if self.dateOffset != 0 {
              self.dateOffset = 0
            } else {
              timeTravelVisible = false
            }
          } else {
            timeTravelVisible = true
          }
        }
      }) {
        VStack {
          if timeTravelVisible {
            Text("\(selectedDate, style: .date)")
              .foregroundColor(.primary)
          }
          if let duration = calculator.today.duration.colloquialTimeString {
            Text("\(duration)")
              .font(.footnote)
              .foregroundColor(.secondary)
          }
        }
      }
      .buttonStyle(SecondaryButtonStyle())
      
      if timeTravelVisible {
        CustomSlider(value: $dateOffset, range: (-182.0, 182.0)) { modifiers in
          ZStack {
            Group {
              VisualEffectView.SystemMaterial()
                .modifier(modifiers.barRight)
              
              VisualEffectView.SystemMaterial()
                .modifier(modifiers.barLeft)
            }.cornerRadius(24)
            
            VStack(spacing: 0) {
              Image(systemName: "arrowtriangle.down.fill").imageScale(.small)
                .padding(.vertical, -2)
              Rectangle().frame(width: 2)
            }.foregroundColor(.accentColor)
            .modifier(modifiers.knob)
          }
        }.frame(height: 16).padding()
      }
      
      SundialView(
        waveSize: waveSize
      )
      .frame(height: waveSize * 2.5)
    }
  }
}


struct SolarTimeMachine_Previews: PreviewProvider {
    static var previews: some View {
      SolarTimeMachine(dateOffset: .constant(0), selectedDate: .constant(Date()), calculator: .shared)
    }
}
