//
//  AddVoiceShortcutView.swift
//  FindMe
//
//  Created by Kirill Pyulzyu on 28.08.2020.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import IntentsUI

struct AddVoiceShortcutView: UIViewControllerRepresentable {
  //MARK: - COORDINATOR
  func makeCoordinator() -> Coordinator {
    return Coordinator(context: self)
  }
  
  class Coordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    let context: AddVoiceShortcutView
    
    init(context: AddVoiceShortcutView) {
      self.context = context
    }
    
    //MARK: INUIAddVoiceShortcutViewControllerDelegate
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
      context.presentationMode.wrappedValue.dismiss()
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
      context.presentationMode.wrappedValue.dismiss()
    }
  }
  
  //MARK: - VIEWCONTROLLER
  @Environment(\.presentationMode) var presentationMode
  var addVoiceShortcutVC: INUIAddVoiceShortcutViewController
  
  func makeUIViewController(context: Context) -> INUIAddVoiceShortcutViewController {
    self.addVoiceShortcutVC.delegate = context.coordinator
    return self.addVoiceShortcutVC
  }
  
  func updateUIViewController(_ uiViewController: INUIAddVoiceShortcutViewController, context: Context) {
    uiViewController.becomeFirstResponder()
  }
  
}

