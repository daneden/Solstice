//
//  AlignedIconLabelStyle.swift
//  Solstice
//
//  Created by Daniel Eden on 18/09/2025.
//

import SwiftUI
import Suite

@Observable
fileprivate class IconWidthObserver {
	static let shared = IconWidthObserver()
	
	var iconWidth: Double = 40
	
	func updateIconWidth(_ newValue: Double) {
		iconWidth = max(iconWidth, newValue)
	}
}

fileprivate extension EnvironmentValues {
	@Entry var iconWidth = IconWidthObserver.shared
}

struct AlignedIconLabelStyle: LabelStyle {
	@Environment(\.iconWidth) private var iconWidthObserver: IconWidthObserver
	@State private var iconSize: CGSize = .zero
	
	func makeBody(configuration: Configuration) -> some View {
		HStack {
			HStack {
				configuration.icon
					.imageScale(.large)
					.foregroundStyle(.tint)
					.readSize($iconSize)
					.task(id: iconSize) {
						iconWidthObserver.updateIconWidth(iconSize.width)
					}
			}
			.frame(width: iconWidthObserver.iconWidth)
			.padding(.leading, -8)
#if !os(watchOS)
			.alignmentGuide(.listRowSeparatorLeading) { d in
				CGFloat(iconWidthObserver.iconWidth)
			}
#endif
			
			configuration.title
		}
	}
}

fileprivate struct AlignedIconLabelStylePreviewView: View {
	var labels: [(Label, UUID)] = [
		(Label("Label", systemImage: "heart"), UUID()),
		(Label("Label", systemImage: "rectangle.and.pencil.and.ellipsis"), UUID()),
		(Label("Label", systemImage: "arrowshape.bounce.right"), UUID())
	]
	
	@State var maxWidth: Double = 0
	var body: some View {
		List {
			Section {
				ForEach(labels, id: \.1) { (label, _) in
					label
				}
			}
			
			Section {
				ForEach(labels, id: \.1) { (label, _) in
					label
				}
			}
			.labelStyle(AlignedIconLabelStyle())
		}
	}
}

#Preview {
    AlignedIconLabelStylePreviewView()
}
