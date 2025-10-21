//
//  GraphicalLocationListRow.swift
//  Solstice
//
//  Created by Daniel Eden on 21/10/2025.
//

import SwiftUI
import TimeMachine
import Solar

struct GraphicalLocationListRow<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine
	var location: Location
	
	var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: location.coordinate)
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
			.listRowSeparator(.hidden)
			.listRowBackground(Color.clear)
			.listRowInsets(.zero)
	}
}

#Preview {
	GraphicalLocationListRow(location: TemporaryLocation.placeholderLondon)
}
