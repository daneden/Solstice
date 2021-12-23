//
//  SheetPresentationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 23/12/2021.
//

import Foundation
import SwiftUI

class SheetPresentationManager: ObservableObject {
  enum PresentationState: Identifiable {
    case settings, location
    
    var id: Int {
      hashValue
    }
  }
  
  @Published var activeSheet: PresentationState? = nil
}
