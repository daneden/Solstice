//
//  AnnualSolarEvent.swift
//  Solstice
//
//  Created by Daniel Eden on 29/06/2024.
//

import SwiftUI

enum AnnualSolarEvent: CaseIterable, Codable, Hashable {
	case marchEquinox, juneSolstice, septemberEquinox, decemberSolstice
	
	var description: LocalizedStringKey {
		switch self {
		case .marchEquinox:
			return "March equinox"
		case .juneSolstice:
			return "June solstice"
		case .septemberEquinox:
			return "September equinox"
		case .decemberSolstice:
			return "December solstice"
		}
	}
	
	var shortMonthDescription: LocalizedStringKey {
		switch self {
		case .marchEquinox:
			return "March"
		case .juneSolstice:
			return "June"
		case .septemberEquinox:
			return "September"
		case .decemberSolstice:
			return "December"
		}
	}
	
	var shortEventDescription: LocalizedStringKey {
		switch self {
		case .marchEquinox, .septemberEquinox:
			return "Equinox"
		case .juneSolstice, .decemberSolstice:
			return "Solstice"
		}
	}
	
	var sunAngle: Double {
		switch self {
		case .marchEquinox:
			return -.pi / 2
		case .septemberEquinox:
			return .pi / 2
		case .juneSolstice:
			return 0
		case .decemberSolstice:
			return .pi
		}
	}
}
