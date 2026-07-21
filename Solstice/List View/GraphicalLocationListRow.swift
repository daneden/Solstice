//
//  GraphicalLocationListRow.swift
//  Solstice
//
//  Created by Daniel Eden on 21/10/2025.
//

import SwiftUI
import TimeMachine

struct GraphicalLocationListRow<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine
	var location: Location

	var solar: NTSolar? {
		NTSolar(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
	}

	var body: some View {
		LocationListRow(location: location, headingFontWeight: .semibold)
			.foregroundStyle(.white)
			.fontWeight(.medium)
			.blendMode(.plusLighter)
			.shadow(color: .black.opacity(0.3), radius: 6, y: 2)
			.padding()
			.background {
				solar?.view
					.clipShape(.rect(cornerRadius: 20, style: .continuous))
			}
		#if os(iOS)
			.background { FocusHaloShape(cornerRadius: 20) }
		#endif
			.listRowSeparator(.hidden)
			.listRowBackground(Color.clear)
			.listRowInsets(.zero)
	}
}

#if os(iOS)
	/// Shapes the keyboard focus halo to match the row's rounded background.
	/// SwiftUI has no focus-shape API on iOS (`ContentShapeKinds.focusEffect` is
	/// macOS/tvOS-only and `focusEffectDisabled()` has no effect on iOS), so the
	/// halo is configured on the enclosing collection view cell via UIKit, per
	/// WWDC21 "Focus on iPad keyboard navigation".
	private struct FocusHaloShape: UIViewRepresentable {
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

#Preview {
	GraphicalLocationListRow(location: TemporaryLocation.placeholderLondon)
}
