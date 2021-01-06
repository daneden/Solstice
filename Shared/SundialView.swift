//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  var waveSize = 75.0
  
  var wave: some View {
    Wave(amplitude: waveSize, frequency: .pi * 2, phase: .pi / 2)
      .stroke(Color.secondarySystemFill, lineWidth: 2)
  }
  
  var body: some View {
    ZStack {
      GeometryReader { geometry in
        ZStack {
          wave
          Circle()
            .frame(width: CGFloat(waveSize / 1.75))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .offset(x: -80.0, y: -15)
        }.offset(y: 10)
        
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
        SundialView()
    }
}
