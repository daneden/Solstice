//
//  AnyTransition+VerticalMove.swift
//  Solstice
//
//  Created by Daniel Eden on 15/09/2023.
//

import SwiftUI

extension AnyTransition {
	static var verticalMove: AnyTransition {
		.asymmetric(
			insertion: .move(edge: .top),
			removal: .move(edge: .bottom)
		)
		.combined(with: .opacity)
	}
	
	static var horizontalMove: AnyTransition {
		.asymmetric(
			insertion: .move(edge: .leading),
			removal: .move(edge: .trailing)
		)
		.combined(with: .opacity)
	}
}
