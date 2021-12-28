//
//  AdaptiveLabelStyle.swift
//  Solstice
//
//  Created by Daniel Eden on 28/12/2021.
//

import SwiftUI

#if os(watchOS)
struct AdaptiveLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .firstTextBaseline) {
      configuration.icon
      configuration.title
    }
    .foregroundStyle(.secondary)
    .imageScale(.small)
    .font(.caption)
  }
}
#else
typealias AdaptiveLabelStyle = DefaultLabelStyle
#endif

struct AdaptiveLabelStyle_Previews: PreviewProvider {
    static var previews: some View {
      Label("Hello, world", systemImage: "sun.max")
        .labelStyle(AdaptiveLabelStyle())
    }
}
