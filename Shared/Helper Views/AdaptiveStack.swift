//
//  AdaptiveStack.swift
//  Solstice
//
//  Created by Daniel Eden on 28/12/2021.
//

import Foundation
import SwiftUI

struct AdaptiveStack<Content: View>: View {
  var content: () -> Content
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    if isWatch {
      VStack(alignment: .leading) {
        content()
      }
    } else {
      HStack {
        content()
      }
    }
  }
}
