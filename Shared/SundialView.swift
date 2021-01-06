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
  var offset = 0.0
  
  var wave: some View {
    Wave(amplitude: waveSize, frequency: .pi * 2, phase: .pi / 2)
      .stroke(Color.secondary, lineWidth: 3)
      .offset(y: -1.5)
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
            .shadow(color: Color.white.opacity(0.6), radius: 10, x: 0.0, y: 0.0)
        }.offset(y: CGFloat(offset * waveSize * 2))
        
        Rectangle()
          .fill(Color.clear)
          .frame(height: geometry.size.height / 2)
          .background(VisualEffectView(effect: UIBlurEffect(style: .prominent)))
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
