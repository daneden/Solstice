//
//  AppStorage.extension.swift
//  Solstice
//
//  Created by Daniel Eden on 20/01/2021.
//

import SwiftUI

extension AppStorage {
  init(_ kv: UDValuePair<Value>) where Value == String {
    self.init(wrappedValue: kv.value, kv.key, store: solsticeUDStore)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == Bool {
    self.init(wrappedValue: kv.value, kv.key, store: solsticeUDStore)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == TimeInterval {
    self.init(wrappedValue: kv.value, kv.key, store: solsticeUDStore)
  }
}
