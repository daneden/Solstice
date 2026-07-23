//
//  ListRowPlatterRadius.swift
//  Solstice
//
//  Created by Daniel Eden on 23/07/2026.
//

#if os(visionOS)
	import SwiftUI
	import UIKit

	/// Rounds the system-drawn selection platter of the enclosing list cell.
	/// SwiftUI's only alternative — replacing the platter with a
	/// `listRowBackground` driven by selection state — makes every selection
	/// change re-render the sidebar rows, which visibly slows navigation, so
	/// the radius is set on the cell's background configuration instead and
	/// selection rendering stays in UIKit.
	struct ListRowPlatterRadius: UIViewRepresentable {
		var cornerRadius: CGFloat

		func makeUIView(context _: Context) -> PlatterShapingView {
			PlatterShapingView(cornerRadius: cornerRadius)
		}

		func updateUIView(_ uiView: PlatterShapingView, context _: Context) {
			uiView.cornerRadius = cornerRadius
		}

		final class PlatterShapingView: UIView {
			var cornerRadius: CGFloat = 0 {
				didSet {
					guard cornerRadius != oldValue else { return }
					hookedCell = nil
					hookEnclosingCellIfNeeded()
				}
			}

			private weak var hookedCell: UICollectionViewCell?

			convenience init(cornerRadius: CGFloat) {
				self.init(frame: .zero)
				self.cornerRadius = cornerRadius
				isUserInteractionEnabled = false
			}

			override func layoutSubviews() {
				super.layoutSubviews()
				hookEnclosingCellIfNeeded()
			}

			private func hookEnclosingCellIfNeeded() {
				guard let cell = enclosingCell, cell !== hookedCell else { return }
				hookedCell = cell
				let radius = cornerRadius
				let inherited = cell.configurationUpdateHandler
				// Chain rather than replace: the list may install its own handler,
				// and reapplying on every state change is what keeps the radius
				// after the system rebuilds the background for selection.
				cell.configurationUpdateHandler = { cell, state in
					inherited?(cell, state)
					if var background = cell.backgroundConfiguration,
					   background.cornerRadius != radius
					{
						background.cornerRadius = radius
						cell.backgroundConfiguration = background
					}
				}
				cell.setNeedsUpdateConfiguration()
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
