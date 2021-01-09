//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  private let dayBegins = Date().startOfDay
  private let dayEnds = Date().endOfDay
  
  private var calculator = SolarCalculator()
  
  private var circleSize: CGFloat = 24
  private var scrimCompensation: CGFloat = 40
  
  private var offset: CGFloat {
    let daylightBegins = calculator.today?.begins ?? dayBegins
    let daylightEnds = calculator.today?.ends ?? dayEnds
    let daylightLength = daylightBegins.distance(to: daylightEnds)
    let dayLength = dayBegins.distance(to: dayEnds)
    
    return CGFloat(daylightLength / dayLength)
  }
  
  private var duration: DateComponents? {
    return calculator.today?.durationComponents
  }
  
  private var waveSize: CGFloat = 80.0
  private var currentPosition: CGFloat {
    let dayLength = dayBegins.distance(to: dayEnds)
    return CGFloat(dayBegins.distance(to: Date()) / dayLength)
  }
  
  private var phaseOffset: CGFloat {
    let peak = calculator.today?.peak ?? Date()
    let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
    let distanceFromNoon = noon?.distance(to: peak)
    print(peak)
    let result = Double(distanceFromNoon ?? 0.0) / 60 / 60 / 24 * (Double.pi / 2)
    return CGFloat(result)
  }
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        SundialWave(size: waveSize, offset: phaseOffset)
        
        SundialSun(
          frameWidth: geometry.size.width,
          position: currentPosition + phaseOffset,
          phaseOffset: phaseOffset,
          arcSize: waveSize
        )
        
        Rectangle()
          .fill(Color.systemBackground.opacity(0.55))
          .frame(height: (waveSize * 2) - (waveSize * offset) + scrimCompensation)
          .overlay(
            Rectangle()
              .fill(Color.clear)
              .frame(height: 2, alignment: .top)
              .background(VisualEffectView.SystemInvertedRuleMaterial()),
            alignment: .top
          )
          .offset(y: (offset * waveSize) + scrimCompensation / 2)
        
        if let duration = duration {
          Text("\(duration.hour ?? 0)hrs, \(duration.minute ?? 0)min")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(4)
            .padding(.horizontal, 4)
            .background(VisualEffectView.SystemMaterial())
            .cornerRadius(8)
        }
      }.fixedSize(horizontal: false, vertical: true).offset(y: (offset * waveSize))
    }
  }
}

struct SundialView_Previews: PreviewProvider {
  static var previews: some View {
    SundialView()
  }
}

struct SundialWave: View {
  var size: CGFloat
  var offset: CGFloat
  
  var body: some View {
    Wave(
      amplitude: size,
      frequency: .pi * 2,
      phase: (.pi / 2) + offset
    )
    .stroke(Color.opaqueSeparator, lineWidth: 3)
    .offset(y: -1.5)
  }
}


struct SundialSun: View {
  let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

  var circleSize: CGFloat = 24.0
  var sunColor = Color.primary
  var frameWidth: CGFloat
  var position: CGFloat
  var phaseOffset: CGFloat
  var arcSize: CGFloat
  
  var body: some View {
    Circle()
      .fill(sunColor)
      .frame(width: circleSize, alignment: .center)
      .position(x: 0, y: arcSize)
      .offset(
        x: (frameWidth * fmod(position, 1)) + circleSize / 2,
        y: sin((position * .pi * 2) - .pi / 4) * -arcSize
      )
      .shadow(color: sunColor.opacity(0.6), radius: 10, x: 0.0, y: 0.0)
  }
}
