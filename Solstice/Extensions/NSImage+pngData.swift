//
//  NSImage+pngData.swift
//  Solstice
//
//  Created by Daniel Eden on 05/03/2025.
//

import SwiftUI

#if os(macOS)
extension NSImage {
	func pngData() -> Data? {
		guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
			return nil
		}
		
		let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
		return bitmapRep.representation(using: .png, properties: [:])
	}
}
#endif
