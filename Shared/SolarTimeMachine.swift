//
//  SolarTimeMachine.swift
//  Solstice
//
//  Created by Daniel Eden on 19/01/2021.
//

import SwiftUI

struct SolarTimeMachine: View {
  @Binding var timeTravelVisible: Bool
  @Binding var dateOffset: Double
  @Binding var selectedDate: Date
  
  var calculator: SolarCalculator
  var body: some View {
    VStack {
      VStack {
        if timeTravelVisible {
          Text("\(selectedDate, style: .date)")
        }
        if let duration = calculator.today.duration.colloquialTimeString {
          Text("\(duration)")
            .font(.footnote)
            .foregroundColor(.secondary)
        }
      }
      .foregroundColor(timeTravelVisible ? .primary : .secondary)
      .padding(6)
      .padding(.horizontal, 6)
      .background(VisualEffectView.SystemMaterial())
      .cornerRadius(8)
      .onTapGesture {
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
      }
      
      if timeTravelVisible {
        TimeMachineView(value: $dateOffset, range: (-182.0, 182.0)) { modifiers in
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
        calculator: calculator,
        waveSize: 80.0
      )
        .frame(height: 200)
    }
  }
}


struct SolarTimeMachine_Previews: PreviewProvider {
    static var previews: some View {
      SolarTimeMachine(timeTravelVisible: .constant(true), dateOffset: .constant(0), selectedDate: .constant(Date()), calculator: .shared)
    }
}
