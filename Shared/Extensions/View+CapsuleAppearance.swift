//
//  View+CapsuleAppearance.swift
//  Solstice
//
//  Created by Daniel Eden on 09/12/2021.
//

import Foundation
import SwiftUI

struct CapsuleModifier: ViewModifier {
  var appearAsCapsule: Bool = true
  
  func body(content: Content) -> some View {
    content
      .padding(4)
      .padding(.horizontal, 4)
      .background(appearAsCapsule ? Color.accentColor : .clear)
      .foregroundStyle(appearAsCapsule ? Color.white : .primary)
      .cornerRadius(6)
      .padding(-4)
      .padding(.horizontal, -4)
  }
}

extension View {
  func capsuleAppearance(on: Bool) -> some View {
    modifier(CapsuleModifier(appearAsCapsule: on))
  }
}
