//
//  CustomLabel.swift
//  Solstice
//
//  Created by Daniel Eden on 08/01/2021.
//

import SwiftUI

struct CustomLabel: View {
  var label: String
  var systemImage: String
  var withColoredImage: Bool
  
  init(_ label: String, systemImage: String, withColoredImage: Bool = false) {
    self.label = label
    self.systemImage = systemImage
    self.withColoredImage = withColoredImage
  }
  
  var body: some View {
    HStack {
      Image(systemName: systemImage)
        .renderingMode(withColoredImage ? .original : .template)
      Text(label)
    }
  }
}

struct CustomLabel_Previews: PreviewProvider {
    static var previews: some View {
        CustomLabel("Hello", systemImage: "sun.fill")
    }
}
