//
//  GraphicalLocationListRow.swift
//  Solstice
//
//  Created by Daniel Eden on 21/10/2025.
//

import SwiftUI
import TimeMachine

struct GraphicalLocationListRow<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine
	var location: Location

	var solar: NTSolar? {
		NTSolar(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
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
					// Darken slightly so the plusLighter row text stays legible over bright skies.
					.overlay { Color.black.opacity(0.18) }
					.clipShape(.rect(cornerRadius: 20, style: .continuous))
			}
		#if os(iOS)
			.background { FocusHaloShape(cornerRadius: 20) }
		#endif
			.listRowSeparator(.hidden)
			.listRowBackground(Color.clear)
			.listRowInsets(.zero)
	}
}

#Preview {
	GraphicalLocationListRow(location: TemporaryLocation.placeholderLondon)
}
