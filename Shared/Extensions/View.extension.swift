//
//  View.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2021.
//

import SwiftUI

extension View {
  /**
   Applies iOS-only modifiers. Usage:
   ```
   View
     .iOS {
       // Will apply a red background only on iOS
       $0.background(Color.red)
     }
   ```
   */
  func iOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
    #if os(iOS)
    return modifier(self)
    #else
    return self
    #endif
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.secondary)
      .padding(6)
      .padding(.horizontal, 4)
      .background(VisualEffectView.SystemThinMaterial())
      .cornerRadius(8)
  }
}
