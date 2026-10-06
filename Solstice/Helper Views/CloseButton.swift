//
//  CloseButton.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2026.
//

import SwiftUI

/// Dismisses a sheet. Uses the system close button where available; the fallback keeps a
/// symbol so the button still reads when toolbars lay out vertically.
struct CloseButton: View {
	let action: () -> Void

	var body: some View {
		if #available(iOS 26, macOS 26, visionOS 26, watchOS 26, *) {
			Button(role: .close, action: action)
		} else {
			Button("Close", systemImage: "xmark", action: action)
		}
	}
}
