//
//  InformationSheetView.swift
//  Solstice
//
//  Created by Daniel Eden on 22/03/2023.
//

import SwiftUI

fileprivate enum Event: CaseIterable, Codable, Hashable {
	case marchEquinox, juneSolstice, septemberEquinox, decemberSolstice
	
	var description: LocalizedStringKey {
		switch self {
		case .marchEquinox:
			return "March Equinox"
		case .juneSolstice:
			return "June Solstice"
		case .septemberEquinox:
			return "September Equinox"
		case .decemberSolstice:
			return "December Solstice"
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
	
	var sunAngle: CGFloat {
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

struct EquinoxAndSolsticeInfoView: View {
	@State private var selection: Event = .juneSolstice
	
	var body: some View {
		GeometryReader { geometry in
			Form {
				Section {
					ZStack(alignment: .top) {
						HStack {
							VStack(alignment: .trailing, spacing: 0) {
								Text(selection.shortMonthDescription)
									.fontWeight(.semibold)
								Text(selection.shortEventDescription)
							}
							.font(.subheadline)
							
							SolarSystemMiniMap(angle: selection.sunAngle, size: 40)
								.foregroundStyle(Color.gray)
						}
						.padding()
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity, alignment: .trailing)
						
						EarthModelView(rotationAmount: Double(selection.sunAngle))
							.frame(height: min(geometry.size.width, 400))
					}
					.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
					.listRowSeparator(.hidden)
					
					Picker(selection: $selection.animation()) {
						ForEach(Event.allCases, id: \.self) { eventType in
							Text(eventType.description)
						}
					} label: {
						Text("View event:")
					}
					
					Text("The equinox and solstice define the transitions between the seasons of the astronomical calendar and are a key part of the Earth’s orbit around the Sun.")
					
					VStack(alignment: .leading) {
						Text("Equinox")
							.font(.headline)
						Text("The equinox occurs twice a year, in March and September, and mark the points when the Sun crosses the equator’s path. During the equinox, day and night are around the same length all across the globe.")
					}
					
					VStack(alignment: .leading) {
						Text("Solstice")
							.font(.headline)
						Text("The solstice occurs twice a year, in June and December (otherwise known as the summer and winter solstices), and mark the sun’s northernmost and southernmost excursions. During the June solstice, the Earth’s northern hemisphere is pointed towards the sun, resulting in increased sunlight and warmer temperatures; the same is true for the southern hemisphere during the December solstice.")
					}
					
				} footer: {
					Text("Imagery Source: [NASA Visible Earth Catalog](https://visibleearth.nasa.gov/collection/1484/blue-marble)")
				}
			}
			.formStyle(.grouped)
			.navigationTitle("Equinox and Solstice")
		}
	}
}

struct InformationSheetView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			EquinoxAndSolsticeInfoView()
		}
	}
}
