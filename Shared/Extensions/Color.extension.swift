//
//  Color.extension.swift
//
//  Created by Daniel Eden on 30/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

#if !os(macOS)
import UIKit
typealias TColor = UIColor
#else
import AppKit
typealias TColor = NSColor
#endif

extension Color {
  /**
   Separator Colors
   */
  #if os(macOS)
  static var separator = Color(TColor.separatorColor)
  #elseif os(iOS)
  static var separator = Color(TColor.separator)
  static var opaqueSeparator = Color(TColor.opaqueSeparator)
  #else
  static var opaqueSeparator = Color.gray
  #endif
  
  
  /**
   System Fills/Background
   */
  #if os(iOS)
  static var systemFill = Color(TColor.systemFill)
  static var systemBackground = Color(TColor.systemBackground)
  static var secondarySystemBackground = Color(TColor.secondarySystemBackground)
  #elseif os(watchOS)
  static var systemFill = Color.black
  static var systemBackground = Color.black
  #endif
}
