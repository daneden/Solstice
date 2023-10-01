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
	
	static func buildEither(first component: String) -> String {
		return component
	}
	
	static func buildEither(second component: String) -> String {
		return component
	}
	
	static func buildArray(_ components: [String]) -> String {
		components.joined(separator: "\n")
	}
	
	static func buildOptional(_ component: String?) -> String {
		return component ?? ""
	}	
}
