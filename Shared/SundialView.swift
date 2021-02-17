//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  @ObservedObject var calculator: SolarCalculator = .shared
  var waveSize: CGFloat = 80.0
  
  private var dayBegins: Date {
    calculator.baseDate.startOfDay
  }
  private var dayEnds: Date {
    calculator.baseDate.endOfDay
  }
  
  /**
   Creates a margin around the sundial to clip the sun's shadow/glow
   */
  private var scrimCompensation: CGFloat {
    waveSize / 2
  }
  
  /**
   Determines the proportion of the day that has daylight
   */
  private var offset: CGFloat {
    let daylightBegins = calculator.today.begins
    let daylightEnds = calculator.today.ends
    let daylightLength = daylightBegins.distance(to: daylightEnds)
    let dayLength = dayBegins.distance(to: dayEnds)
    
    return CGFloat(daylightLength / dayLength)
  }
  
  /**
   Determines the current time as a percentage of the day length
   */
  private var currentPosition: CGFloat {
    let dayLength = dayBegins.distance(to: dayEnds)
    
    let position = CGFloat(dayBegins.distance(to: calculator.baseDate) / dayLength)
    return position
  }
  
  /**
   Determines the offset of noon compared to the sun's peak
   */
  private var phase: CGFloat {
    let peak = calculator.today.peak ?? Date()
    let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: peak)!
    let distanceFromNoon = noon.distance(to: peak)
    
    /**
     The difference between noon and the peak of the sun for the given date represented as a fraction of a day’s length
     */
    let result = distanceFromNoon / 60 / 60 / 24
    
    /**
     The phase is constantly offset by half pi since we want the peak of the curve to be positioned at noon by default
     */
    return CGFloat(result + .pi / 2)
  }
  
  /**
   The sundial should be animated, but only shortly after mounting, hence the `nil` setting here
   */
  @State var sundialAnimation: Animation? = nil
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        SundialWave(size: waveSize, phase: phase)
        
        SundialSun(
          frameWidth: geometry.size.width,
          position: currentPosition,
          phase: phase,
          arcSize: waveSize
        )
        
        Color.systemBackground.opacity(0.55)
          .frame(height: (waveSize * 2) - (waveSize * offset) + scrimCompensation)
          .overlay(
            Color.tertiarySystemGroupedBackground
              .frame(height: 1, alignment: .top),
            alignment: .top
          )
          .offset(y: (offset * waveSize) + scrimCompensation / 2)
      }
      .clipShape(Rectangle())
      .overlay(SundialInnerShadowOverlay())
      .animation(sundialAnimation)
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          sundialAnimation = easingSpringAnimation
        }
      }
    }
  }
}

struct SundialWave: View {
  var size: CGFloat
  var phase: CGFloat
  var strokeWidth: CGFloat = 2.0
  
  var body: some View {
    Wave(
      amplitude: size,
      frequency: .pi * 2,
      phase: phase
    )
    .stroke(Color.opaqueSeparator, lineWidth: strokeWidth)
  }
}


struct SundialSun: View {
  @Environment(\.widgetFamily) var family
  
  @State var circleSize: CGFloat = 22.0
  var sunColor = Color.primary
  var frameWidth: CGFloat
  var position: CGFloat
  var phase: CGFloat
  var arcSize: CGFloat
  
  var n: CGFloat {
    position + phase
  }
  
  var isWidget: Bool {
    family == .systemLarge || family == .systemSmall || family == .systemMedium
  }
  
  var body: some View {
    let waveLength = frameWidth / (.pi * 2)
    let relativeX = (position * frameWidth) / max(waveLength, 1.0)
    let sine = sin(phase + relativeX)
    let y = arcSize * sine
    
    Circle()
      .frame(width: circleSize)
      .foregroundColor(sunColor)
      .shadow(color: sunColor.opacity(isWidget ? 0.4 : 0.6), radius: isWidget ? 5 : 10, x: 0.0, y: 0.0)
      .offset(
        x: (frameWidth * fmod(position, 1)) - (frameWidth / 2),
        y: y
      )
  }
}

struct SundialInnerShadowOverlay: View {
  var body: some View {
    HStack {
      LinearGradient(
        gradient: Gradient(colors: [.systemBackground, Color.systemBackground.opacity(0)]),
        startPoint: .leading,
        endPoint: .trailing
      )
        .frame(width: 40)
      Spacer()
      LinearGradient(
        gradient: Gradient(colors: [.systemBackground, Color.systemBackground.opacity(0)]),
        startPoint: .trailing,
        endPoint: .leading
      )
        .frame(width: 40)
    }
  }
}
