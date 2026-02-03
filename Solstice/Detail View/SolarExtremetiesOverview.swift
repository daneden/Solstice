//
//  SolarExtremetiesOverview.swift
//  Solstice
//
//  Created by Dan Eden on 22/10/2025.
//

import SwiftUI
import TimeMachine

struct SolarExtremetiesOverview<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine
	
	var location: Location
	
	var body: some View {
		if let shortestDay,
			 let longestDay {
			SolarExtremityView(solar: longestDay, extremity: .longest)
			SolarExtremityView(solar: shortestDay, extremity: .shortest)
		}
	}
}

fileprivate struct SolarExtremityView: View {
	@Environment(\.timeMachine) private var timeMachine
	
	enum Extremity {
		case longest, shortest
		
		var title: LocalizedStringKey {
			switch self {
			case .longest:
				return "Longest day"
			case .shortest:
				return "Shortest day"
			}
		}
		
		var imageName: String {
			switch self {
			case .longest:
				return "sun.max"
			case .shortest:
				return "sun.min"
			}
		}
	}
	
var solar: NTSolar
	var extremity: Extremity
	
	var body: some View {
		CompatibleDisclosureGroup {
			Button("Time travel to date", systemImage: "clock.arrow.2.circlepath") {
				withAnimation {
					timeMachine.date = solar.date
				}
			}
			
			let duration = Duration.seconds(solar.daylightDuration).formatted(.units(maximumUnitCount: 2))
			
			Label {
				AdaptiveStack {
					Text(duration)
				} label: {
					Text("Total daylight")
				}
			} icon: {
				Image(systemName: "hourglass")
			}
			
			if let sunrise = solar.sunrise {
				Label {
					AdaptiveStack {
						Text(sunrise, style: .time)
					} label: {
						Text("Sunrise")
					}
				} icon: {
					Image(systemName: "sunrise")
				}
			}
			
			if let sunset = solar.sunset {
				Label {
					AdaptiveStack {
						Text(sunset, style: .time)
					} label: {
						Text("Sunset")
					}
				} icon: {
					Image(systemName: "sunset")
				}
			}
		} label: {
			Label {
				AdaptiveStack {
					Text(solar.date, style: .date)
				} label: {
					Text(extremity.title)
				}
			} icon: {
				Image(systemName: extremity.imageName)
			}
		}
	}
}

fileprivate struct CompatibleDisclosureGroup<Content: View, Label: View>: View {
	@ViewBuilder var content: Content
	@ViewBuilder var label: Label
	
	@State private var isOpen = false
	
	var body: some View {
		#if os(watchOS)
		Toggle(isOn: $isOpen) {
			label
		}
		.toggleStyle(DisclosureGroupToggleStyle())
		if isOpen {
			content
				.padding(.leading)
		}
		#else
		DisclosureGroup(isExpanded: $isOpen) {
			content
		} label: {
			label
		}
		#endif
	}
}

extension CompatibleDisclosureGroup {
	struct DisclosureGroupToggleStyle: ToggleStyle {
		func makeBody(configuration: Configuration) -> some View {
			Button {
				withAnimation {
					configuration.isOn.toggle()
				}
			} label: {
				HStack {
					configuration.label
					Spacer()
					Image(systemName: "chevron.forward")
						.rotationEffect(Angle(degrees: configuration.isOn ? 90 : 0))
						.foregroundStyle(.secondary)
				}
			}
			.tint(.primary)
			.buttonStyle(.borderless)
		}
	}
}

extension SolarExtremetiesOverview {
var decemberSolsticeSolar: NTSolar? {
		let year = calendar.component(.year, from: timeMachine.date)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		return NTSolar(for: decemberSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
	}
	
	var juneSolsticeSolar: NTSolar? {
		let year = calendar.component(.year, from: timeMachine.date)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		return NTSolar(for: juneSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
	}
	
	var longestDay: NTSolar? {
		guard let decemberSolsticeSolar,
					let juneSolsticeSolar else {
			return nil
		}
		
		return decemberSolsticeSolar.daylightDuration > juneSolsticeSolar.daylightDuration ? decemberSolsticeSolar : juneSolsticeSolar
	}
	
	var shortestDay: NTSolar? {
		guard let decemberSolsticeSolar,
					let juneSolsticeSolar else {
			return nil
		}
		
		return decemberSolsticeSolar.daylightDuration < juneSolsticeSolar.daylightDuration ? decemberSolsticeSolar : juneSolsticeSolar
	}
}

#Preview {
	SolarExtremetiesOverview(location: TemporaryLocation.placeholderGreenland)
}
