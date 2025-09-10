//
//  AdaptiveLabelledContent.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation
import SwiftUI

struct StackedLabeledContent<Label: View, Content: View>: View {
	@ViewBuilder var content: Content
	@ViewBuilder var label: Label
	
	
	var stackSpacing: Double {
		#if os(watchOS)
		return 0
		#else
		return 2
		#endif
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: stackSpacing) {
			label
			
			if Label.self is SwiftUI.Label<Text, Image>.Type {
				SwiftUI.Label {
					content
						.foregroundStyle(.secondary)
				} icon: {
					Color.clear.frame(width: 0, height: 0)
				}
			} else {
				content
					.foregroundStyle(.secondary)
			}
		}
	}
}

struct AdaptiveLabeledContent<Label: View, Content: View>: View {
	var content: () -> Content
	var label: () -> Label
	
	init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
		self.content = content
		self.label = label
	}
	
	var body: some View {
		ViewThatFits {
			LabeledContent {
				content()
			} label: {
				label()
			}
			
			#if os(watchOS)
			StackedLabeledContent {
				content()
			} label: {
				label()
			}
			#endif
		}
	}
}
