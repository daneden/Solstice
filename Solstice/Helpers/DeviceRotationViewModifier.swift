//
//  DeviceRotationViewModifier.swift
//  Solstice
//
//  Created by Daniel Eden on 20/05/2025.
//
import SwiftUI

#if canImport(UIKit)
import UIKit

struct DeviceRotationViewModifier: ViewModifier {
	let action: (UIDeviceOrientation) -> Void
	
	func body(content: Content) -> some View {
		content
			.onAppear()
			.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
				action(UIDevice.current.orientation)
			}
	}
}

// A View wrapper to make the modifier easier to use
extension View {
	func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
		self.modifier(DeviceRotationViewModifier(action: action))
	}
}
#endif
