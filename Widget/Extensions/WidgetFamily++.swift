//
//  WidgetFamily++.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 23/02/2023.
//

import WidgetKit

extension WidgetFamily: CaseIterable {
	public static var allCases: [WidgetFamily] {
		[.systemExtraLarge, .systemLarge, .systemMedium, .systemSmall]
	}
}
