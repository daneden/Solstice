//
//  AdaptiveLabelledContent.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation
import SwiftUI

struct AdaptiveLabeledContent<Label: View, Content: View>: View {
	var content: () -> Content
	var label: () -> Label
	
	init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
		self.content = content
		self.label = label
	}
	
	var body: some View {
		ViewThatFits {
			#if !os(watchOS)
			LabeledContent {
				content()
			} label: {
				label()
			}
			#endif
			
			VStack(alignment: .leading, spacing: 2) {
				label()
				
				if Label.self is SwiftUI.Label<Text, Image>.Type {
					SwiftUI.Label {
						content()
							.foregroundStyle(.secondary)
					} icon: {
						Color.clear.frame(width: 0, height: 0)
					}
				} else {
					content()
						.foregroundStyle(.secondary)
				}
			}
		}
	}
}
