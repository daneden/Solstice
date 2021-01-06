//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  var waveSize = 75.0
  var circleSize: CGFloat = 36.0
  var currentPosition: Double
  
  var wave: some View {
    Wave(amplitude: waveSize, frequency: .pi * 2, phase: .pi / 2)
      .stroke(Color.secondarySystemFill, lineWidth: 2)
      .offset(y: -1)
  }
  
  var body: some View {
    ZStack {
      GeometryReader { geometry in
        ZStack {
          wave
          Circle()
            .frame(width: circleSize)
            .position(x: -circleSize / 2, y: geometry.size.height / 2)
            .offset(
              x: geometry.size.width * CGFloat(currentPosition),
              y: CGFloat(sin((currentPosition - .pi / 4) * .pi * 2) * waveSize))
        }
        
        Rectangle()
          .fill(Color.clear)
          .frame(height: geometry.size.height / 2)
          .background(VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial)))
          .offset(y: geometry.size.height / 2)
      }
    }.edgesIgnoringSafeArea(.all)
  }
}

struct SundialView_Previews: PreviewProvider {
    static var previews: some View {
      SundialView(currentPosition: 0.75)
    }
}
