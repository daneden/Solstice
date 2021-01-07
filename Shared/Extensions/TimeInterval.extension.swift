//
//  TimeInterval.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import Foundation

extension TimeInterval {
  var timeString: String {
    let ti = Int(self)

    let ms = Int((self) * 1000)

    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)

    return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
  }
}
