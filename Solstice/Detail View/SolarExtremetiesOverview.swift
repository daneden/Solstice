//
//  SolarExtremetiesOverview.swift
//  Solstice
//
//  Created by Dan Eden on 22/10/2025.
//

import SwiftUI
import SunKit
import TimeMachine

struct SolarExtremetiesOverview<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine

	@State private var cachedDecemberSolsticeSun: Sun?
	@State private var cachedJuneSolsticeSun: Sun?

	var location: Location

	var body: some View {
		Group {
			if let shortestDay,
				 let longestDay {
				SolarExtremityView(sun: longestDay, extremity: .longest)
				SolarExtremityView(sun: shortestDay, extremity: .shortest)
			}
		}
		.task(id: solsticeDependencies) {
			updateSolsticeSuns()
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
	
	var sun: Sun
	var extremity: Extremity
	
	var body: some View {
		CompatibleDisclosureGroup {
			Button("Time travel to date", systemImage: "clock.arrow.2.circlepath") {
				withAnimation {
					timeMachine.date = sun.date
				}
			}

			let duration = Duration.seconds(sun.daylightDuration).formatted(.units(maximumUnitCount: 2))

			Label {
				AdaptiveStack {
					Text(duration)
				} label: {
					Text("Total daylight")
				}
			} icon: {
				Image(systemName: "hourglass")
			}

			Label {
				AdaptiveStack {
					Text(sun.sunrise, style: .time)
				} label: {
					Text("Sunrise")
				}
			} icon: {
				Image(systemName: "sunrise")
			}

			Label {
				AdaptiveStack {
					Text(sun.sunset, style: .time)
				} label: {
					Text("Sunset")
				}
			} icon: {
				Image(systemName: "sunset")
			}
		} label: {
			Label {
				AdaptiveStack {
					Text(sun.date, style: .date)
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
	var decemberSolsticeSun: Sun? { cachedDecemberSolsticeSun }
	var juneSolsticeSun: Sun? { cachedJuneSolsticeSun }

	var longestDay: Sun? {
		guard let decemberSolsticeSun,
					let juneSolsticeSun else {
			return nil
		}
		return decemberSolsticeSun.daylightDuration > juneSolsticeSun.daylightDuration ? decemberSolsticeSun : juneSolsticeSun
	}

	var shortestDay: Sun? {
		guard let decemberSolsticeSun,
					let juneSolsticeSun else {
			return nil
		}
		return decemberSolsticeSun.daylightDuration < juneSolsticeSun.daylightDuration ? decemberSolsticeSun : juneSolsticeSun
	}

	var solsticeDependencies: [AnyHashable] {
		let year = calendar.component(.year, from: timeMachine.date)
		return [year, location.coordinate.latitude, location.coordinate.longitude]
	}

	func updateSolsticeSuns() {
		let year = calendar.component(.year, from: timeMachine.date)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		cachedDecemberSolsticeSun = Sun(for: decemberSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
		cachedJuneSolsticeSun = Sun(for: juneSolstice, coordinate: location.coordinate, timeZone: location.timeZone)
	}
}

#Preview {
	SolarExtremetiesOverview(location: TemporaryLocation.placeholderGreenland)
}
