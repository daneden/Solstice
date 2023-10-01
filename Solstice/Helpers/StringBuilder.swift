//
//  StringBuilder.swift
//  Solstice
//
//  Created by Daniel Eden on 01/10/2023.
//

import Foundation

@resultBuilder
struct StringBuilder {
	static func buildBlock(_ parts: String...) -> String {
		parts.joined(separator: " ")
	}
}
