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
			var cornerRadius: CGFloat = 0 {
				didSet {
					guard cornerRadius != oldValue else { return }
					appliedHaloRect = .null
					if let cell = enclosingCell { applyHaloIfNeeded(to: cell) }
				}
			}

			private weak var hookedCell: UICollectionViewCell?
			private weak var appliedCell: UICollectionViewCell?
			private var appliedHaloRect: CGRect = .null

			convenience init(cornerRadius: CGFloat) {
				self.init(frame: .zero)
				self.cornerRadius = cornerRadius
				isUserInteractionEnabled = false
			}

			override func layoutSubviews() {
				super.layoutSubviews()
				guard let cell = enclosingCell else { return }
				hookConfigurationUpdates(on: cell)
				applyHaloIfNeeded(to: cell)
			}

			/// The row content can move within the cell without this view laying
			/// out again (position-only changes don't call `layoutSubviews`), which
			/// left the halo at a stale offset — seen on the current-location row,
			/// which is inserted late and settles after the first layout pass.
			/// Focus and selection are configuration states, so recomputing here
			/// refreshes the rect with settled geometry right when the halo shows.
			private func hookConfigurationUpdates(on cell: UICollectionViewCell) {
				guard cell !== hookedCell else { return }
				hookedCell = cell
				let inherited = cell.configurationUpdateHandler
				cell.configurationUpdateHandler = { [weak self] cell, state in
					inherited?(cell, state)
					guard let self, self.enclosingCell === cell else { return }
					self.applyHaloIfNeeded(to: cell)
				}
			}

			private func applyHaloIfNeeded(to cell: UICollectionViewCell) {
				guard bounds.width > 0, bounds.height > 0 else { return }
				let haloRect = cell.convert(bounds, from: self)
				// Reassigning the effect invalidates layout, so only assign when
				// the geometry actually changes to avoid a layout/focus loop.
				guard haloRect != appliedHaloRect || cell !== appliedCell else { return }
				appliedHaloRect = haloRect
				appliedCell = cell
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
