//
//  DurationPicker.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 16/12/2021.
//

import Foundation
import SwiftUI

struct DurationPicker: UIViewRepresentable {
  @Binding var duration: TimeInterval
  var style: UIDatePickerStyle = .automatic
  
  func makeUIView(context: Context) -> UIDatePicker {
    let datePicker = UIDatePicker()
    datePicker.preferredDatePickerStyle = style
    datePicker.datePickerMode = .countDownTimer
    datePicker.addTarget(context.coordinator, action: #selector(Coordinator.updateDuration), for: .valueChanged)
    return datePicker
  }
  
  func updateUIView(_ datePicker: UIDatePicker, context: Context) {
    datePicker.countDownDuration = duration
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject {
    let parent: DurationPicker
    
    init(_ parent: DurationPicker) {
      self.parent = parent
    }
    
    @objc func updateDuration(datePicker: UIDatePicker) {
      parent.duration = datePicker.countDownDuration
    }
  }
}
