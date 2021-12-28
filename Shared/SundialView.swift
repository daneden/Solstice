//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var calculator: SolarCalculator
  
  var sunSize = 24.0
  var trackWidth = 3.0
  
  private var dayBegins: Date {
    calculator.baseDate.startOfDay
  }
  private var dayEnds: Date {
    calculator.baseDate.endOfDay
  }
  
  /**
   Determines the proportion of the day that has daylight
   */
  private var daylightProportion: CGFloat {
    let daylightBegins = calculator.today.begins
    let daylightEnds = calculator.today.ends
    let daylightLength = daylightBegins.distance(to: daylightEnds)
    let dayLength = dayBegins.distance(to: dayEnds)
    
    return CGFloat(daylightLength / dayLength)
  }
  
  /**
   Determines the current time as a percentage of the day length
   */
  private var currentTime: CGFloat {
    let currentTimeComponents = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: .now)
    let date = Calendar.autoupdatingCurrent.date(bySettingHour: currentTimeComponents.hour!, minute: currentTimeComponents.minute!, second: currentTimeComponents.second!, of: calculator.baseDate)!
    let dayLength = dayBegins.distance(to: dayEnds)
    
    let dst = calculator.timezone.daylightSavingTimeOffset(for: date)
    
    let position = CGFloat((dayBegins.distance(to: calculator.baseDate) - dst) / dayLength)
    return position
  }
  
  /**
   Determines the offset of noon compared to the sun's peak
   */
  private var phaseOffset: CGFloat {
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
  
  var body: some View {
    Canvas { context, size in
      let waveSize = (size.height * 0.55) - (sunSize * 2)
      let sunSizeOffset = sunSize / 2
      
      let x = (currentTime * size.width) - sunSizeOffset
      let y = ((size.height / 2) + (sin((currentTime * .pi * 2) + phaseOffset) * waveSize)) - sunSizeOffset
      
      let horizonRect = CGRect(x: 0, y: (size.height * daylightProportion) + 0.5, width: size.width, height: size.height * 2)
      context.stroke(Path(horizonRect), with: .color(.primary.opacity(0.25)), lineWidth: 0.5)

      
      // Draw above-horizon elements
      context.drawLayer { context in
        context.clip(to: Path(CGRect(
          origin: .zero,
          size: CGSize(width: size.width, height: (size.height * daylightProportion) + 1)
        )))
        
        // Wave shape
        context.stroke(
          wavePath(in: size, amplitude: waveSize, frequency: .pi * 2, phase: phaseOffset),
          with: .color(.secondary.opacity(0.55)),
          lineWidth: trackWidth
        )
        
        // Sun
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: sunSize, height: sunSize)),
          with: .color(.primary)
        )
        
        // Shadow/highlight on sun
        context.addFilter(.blur(radius: sunSize / 4))
        context.fill(
          Path(ellipseIn: CGRect(x: x + (sunSize / 4), y: y + (sunSize / 4), width: sunSize / 2, height: sunSize / 2)),
          with: .color(.systemBackground.opacity(0.25))
        )
        
        // Sun's glow
        context.addFilter(.blur(radius: sunSize / 2))
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: sunSize, height: sunSize)),
          with: .color(.primary.opacity(colorScheme == .dark ? 0.65 : 0.35))
        )
      }
      
      // Draw below-horizon elements
      context.drawLayer { context in
        let strokeWidth = trackWidth
        let strokeOffset = strokeWidth / 2
        
        context.clip(to: Path(CGRect(
          origin: CGPoint(x: 0, y: (size.height * daylightProportion) + 0.5),
          size: size
        )))
        
        context.stroke(
          wavePath(in: size, amplitude: waveSize, frequency: .pi * 2, phase: phaseOffset),
          with: .color(.secondary.opacity(0.35)),
          lineWidth: trackWidth
        )
        
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: sunSize, height: sunSize)),
          with: .color(.systemBackground)
        )
        
        context.stroke(
          Path(ellipseIn: CGRect(x: x + strokeOffset, y: y + strokeOffset, width: sunSize - strokeWidth, height: sunSize - strokeWidth)),
          with: .color(.primary.opacity(0.8)),
          lineWidth: strokeWidth
        )
      }
    }
    .mask {
      LinearGradient(
        stops: [
          Gradient.Stop(color: .clear, location: 0),
          Gradient.Stop(color: .black, location: 0.1),
          Gradient.Stop(color: .black, location: 0.9),
          Gradient.Stop(color: .clear, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
    }
  }
  
  func wavePath(in size: CGSize, amplitude: CGFloat, frequency: CGFloat, phase: CGFloat = 0) -> Path {
    let path = UIBezierPath()
    
    // calculate some important values up front
    let width = CGFloat(size.width)
    let height = CGFloat(size.height)
    // let midWidth = width / 2
    let midHeight = height / 2
    
    // split our total width up based on the frequency
    let wavelength = width / frequency
    
    // plot the starting point
    var relativeX = 0 / max(wavelength, 1.0)
    var sine = sin(phase + relativeX)
    var y = amplitude * sine + midHeight
    
    path.move(to: CGPoint(x: 0, y: y))
    
    // now count across individual horizontal points 3px at a time
    for x in stride(from: 0, through: width, by: 3) {
      // find our current position relative to the wavelength
      relativeX = x / wavelength
      
      // calculate the sine of that position
      sine = sin(phase + relativeX)
      
      // multiply that sine by our strength to determine final offset, then move it down to the middle of our view
      y = amplitude * sine + midHeight
      
      // add a line to here
      path.addLine(to: CGPoint(x: x, y: y))
    }
    
    return Path(path.cgPath)
  }
}
