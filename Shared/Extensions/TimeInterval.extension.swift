//
//  TimeInterval.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import Foundation

extension TimeInterval {
  var localizedString: String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .short
    formatter.allowedUnits = [.hour, .minute, .second]
    let string = formatter.string(from: abs(self)) ?? ""
    return string
  }
}
