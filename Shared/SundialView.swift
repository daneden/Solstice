//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  var waveSize = 80.0
  var circleSize: CGFloat = 24.0
  var currentPosition: Double
  var offset = 0.0
  var sunColor = Color.primary
  var duration: DateComponents?
  
  var quarterOffset: Double {
    offset / 4
  }
  
  var wave: some View {
    Wave(amplitude: waveSize, frequency: .pi * 2, phase: .pi / 2)
      .stroke(Color.opaqueSeparator, lineWidth: 3)
      .offset(y: -1.5)
  }
  
  var body: some View {
    ZStack {
      GeometryReader { geometry in
        ZStack {
          wave
          
          Circle()
            .fill(sunColor)
            .frame(width: circleSize)
            .position(x: -circleSize / 2, y: geometry.size.height / 2)
            .offset(
              x: geometry.size.width * CGFloat(currentPosition),
              y: CGFloat(sin((currentPosition - .pi / 4) * .pi * 2) * waveSize))
            .shadow(color: sunColor.opacity(0.6), radius: 10, x: 0.0, y: 0.0)
          
          Rectangle()
            .fill(Color.systemBackground.opacity(0.5))
            .frame(height: CGFloat(waveSize * 2) - CGFloat(waveSize * offset))
            .overlay(
              Rectangle()
                .frame(width: nil, height: 1, alignment: .top)
                .foregroundColor(Color.opaqueSeparator),
              alignment: .top
            )
            .offset(y: CGFloat(offset * waveSize))
          
          if let duration = duration {
            Text("\(duration.hour ?? 0)hrs, \(duration.minute ?? 0)min")
              .font(.footnote)
              .foregroundColor(.secondary)
              .padding(4)
              .padding(.horizontal, 4)
              .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
              .cornerRadius(8)
          }
        }.offset(y: CGFloat(offset * waveSize))
      }
    }
  }
}

struct SundialView_Previews: PreviewProvider {
    static var previews: some View {
      SundialView(currentPosition: 0.75, duration: DateComponents(hour: 8, minute: 12, second: 36))
    }
}
