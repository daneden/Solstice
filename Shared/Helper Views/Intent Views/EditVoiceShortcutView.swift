//
//  AddVoiceShortcutView.swift
//  FindMe
//
//  Created by Kirill Pyulzyu on 28.08.2020.
//  Copyright © 2020 test. All rights reserved.
//

import SwiftUI
import IntentsUI

struct EditVoiceShortcutView: UIViewControllerRepresentable {
  
  
  //MARK: - COORDINATOR
  func makeCoordinator() -> Coordinator {
    return Coordinator(context: self)
  }
  
  class Coordinator: NSObject, INUIEditVoiceShortcutViewControllerDelegate {
    let context: EditVoiceShortcutView
    
    init(context: EditVoiceShortcutView) {
      self.context = context
    }
    
    
    //MARK: INUIEditVoiceShortcutViewControllerDelegate
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
      context.presentationMode.wrappedValue.dismiss()
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
      context.presentationMode.wrappedValue.dismiss()
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
      context.presentationMode.wrappedValue.dismiss()
    }
  }
  
  //MARK: - VIEWCONTROLLER
  @Environment(\.presentationMode) var presentationMode
  var editVoiceShortcutVC: INUIEditVoiceShortcutViewController
  
  func makeUIViewController(context: Context) -> INUIEditVoiceShortcutViewController {
    self.editVoiceShortcutVC.delegate = context.coordinator
    return self.editVoiceShortcutVC
  }
  
  func updateUIViewController(_ uiViewController: INUIEditVoiceShortcutViewController, context: Context) {
    uiViewController.becomeFirstResponder()
  }
  
}

