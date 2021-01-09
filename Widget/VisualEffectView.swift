//
//  VisualEffectView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 08/01/2021.
//

import SwiftUI

struct VisualEffectView: View {
  var effect: UIVisualEffect?
  var body: some View {
    Rectangle().fill(Color.secondarySystemBackground)
  }
  
  typealias SystemMaterial = VisualEffectView
  typealias SystemInvertedRuleMaterial = VisualEffectView
}

struct VisualEffectView_Previews: PreviewProvider {
    static var previews: some View {
        VisualEffectView()
    }
}
