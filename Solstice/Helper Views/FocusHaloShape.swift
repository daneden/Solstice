//
//  FocusHaloShape.swift
//  Solstice
//
//  Created by Daniel Eden on 23/07/2026.
//

#if os(iOS) || os(visionOS)
	import SwiftUI
	import UIKit

	/// Shapes the focus halo to match a list row's rounded background.
	/// SwiftUI has no focus-shape API on iOS or visionOS
	/// (`ContentShapeKinds.focusEffect` is macOS/tvOS-only and
	/// `focusEffectDisabled()` has no effect here), so the halo is configured
	/// on the enclosing collection view cell via UIKit, per WWDC21 "Focus on
	/// iPad keyboard navigation".
	struct FocusHaloShape: UIViewRepresentable {
		var cornerRadius: CGFloat

		func makeUIView(context _: Context) -> HaloShapingView {
			HaloShapingView(cornerRadius: cornerRadius)
		}

		func updateUIView(_ uiView: HaloShapingView, context _: Context) {
			uiView.cornerRadius = cornerRadius
		}

		final class HaloShapingView: UIView {
			var cornerRadius: CGFloat = 0
			private var appliedHaloRect: CGRect = .null

			convenience init(cornerRadius: CGFloat) {
				self.init(frame: .zero)
				self.cornerRadius = cornerRadius
				isUserInteractionEnabled = false
			}

			override func layoutSubviews() {
				super.layoutSubviews()
				guard bounds.width > 0, bounds.height > 0, let cell = enclosingCell else { return }
				let haloRect = cell.convert(bounds, from: self)
				// Reassigning the effect invalidates layout, so only assign when
				// the geometry actually changes to avoid a layout/focus loop.
				guard haloRect != appliedHaloRect else { return }
				appliedHaloRect = haloRect
				cell.focusEffect = UIFocusHaloEffect(
					roundedRect: haloRect,
					cornerRadius: cornerRadius,
					curve: .continuous
				)
			}

			private var enclosingCell: UICollectionViewCell? {
				var view = superview
				while let current = view, !(current is UICollectionViewCell) {
					view = current.superview
				}
				return view as? UICollectionViewCell
			}
		}
	}
#endif
