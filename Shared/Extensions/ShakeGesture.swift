//
//  ShakeGesture.swift
//  Solstice
//
//  Created by Daniel Eden on 12/01/2021.
//

import Foundation
import UIKit

extension Notification.Name {
  public static let deviceDidShakeNotification = Notification.Name("DeviceShakeGestureInvoked")
}

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    super.motionEnded(motion, with: event)
    NotificationCenter.default.post(name: .deviceDidShakeNotification, object: event)
  }
}
