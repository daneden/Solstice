//
//  View.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 17/02/2021.
//

import SwiftUI

extension View {
  func buttonAppearance() -> some View {
    return self
      .foregroundColor(.secondary)
      .padding(6)
      .padding(.horizontal, 4)
      .background(VisualEffectView.SystemThinMaterial())
      .cornerRadius(8)
  }
}
