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
			LabeledContent {
				content()
			} label: {
				label()
			}
			
			VStack(alignment: .leading) {
				label()
				content()
					.foregroundStyle(.secondary)
			}
		}
	}
}
