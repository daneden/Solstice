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
					appliedBounds = .null
					if let cell = enclosingCell { applyHaloIfNeeded(to: cell) }
				}
			}

			private weak var hookedCell: UICollectionViewCell?
			private weak var appliedCell: UICollectionViewCell?
			private var appliedBounds: CGRect = .null

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

			/// The list rebuilds a reused cell's focus effect when it's
			/// reconfigured, so — following the `ListRowPlatterRadius` pattern —
			/// chain the cell's `configurationUpdateHandler` to reinstall the halo
			/// after the system rebuilds the cell for a new row.
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

			/// Anchors the halo to this view via `referenceView` instead of
			/// freezing a rect converted into cell coordinates. UIKit then resolves
			/// the halo geometry from this view live, so the ring stays aligned even
			/// when the row content moves within the cell after the effect is
			/// installed — the case the current-location row hit on first launch,
			/// where it's inserted late (after authorization resolves) and settles
			/// with a position-only move that never lays this view out again. The
			/// frozen rect was captured before that settle and left the ring
			/// offset until an unrelated focus change recomputed it.
			private func applyHaloIfNeeded(to cell: UICollectionViewCell) {
				guard bounds.width > 0, bounds.height > 0 else { return }
				// Reassigning the effect invalidates layout, so only assign when the
				// size or target cell changes to avoid a layout/focus loop; the
				// reference view tracks position changes without reassignment.
				guard bounds != appliedBounds || cell !== appliedCell else { return }
				appliedBounds = bounds
				appliedCell = cell
				let effect = UIFocusHaloEffect(
					roundedRect: bounds,
					cornerRadius: cornerRadius,
					curve: .continuous
				)
				effect.referenceView = self
				cell.focusEffect = effect
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
