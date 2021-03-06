//
//  WaveShape.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI
import UIKit

struct Wave: Shape {
  var amplitude: CGFloat
  var frequency: CGFloat
  var phase: CGFloat = 0
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath()
    
    // calculate some important values up front
    let width = CGFloat(rect.width)
    let height = CGFloat(rect.height)
    // let midWidth = width / 2
    let midHeight = height / 2
    
    // split our total width up based on the frequency
    let wavelength = width / frequency
    
    // plot the starting point
    var relativeX = 0 / max(wavelength, 1.0)
    var sine = sin(phase + relativeX)
    var y = amplitude * sine + midHeight
    
    path.move(to: CGPoint(x: 0, y: y))
    
    // now count across individual horizontal points one by one
    for x in stride(from: 0, through: width, by: 1) {
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
