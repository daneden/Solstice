//
//  EclipseOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 11/08/2026.
//

import Suite
import SwiftUI
import TimeMachine

private var eclipseFormatter: RelativeDateTimeFormatter {
	let formatter = RelativeDateTimeFormatter()
	formatter.unitsStyle = .full
	formatter.dateTimeStyle = .named
	return formatter
}

/// Surfaces an upcoming solar eclipse for a location.
///
/// The eclipse itself is worked out by `DetailView`, which owns the `@State` and the
/// task that fills it. Doing it here would be circular: this view renders nothing when
/// there is no eclipse, so a `.task` attached to it would never get the chance to run
/// and find one.
struct EclipseOverview<Location: AnyLocation>: View {
	@Environment(\.timeMachine) var timeMachine: TimeMachine

	var circumstances: EclipseCalculator.LocalCircumstances
	var location: Location

	/// A near-total eclipse is a reason to take the day off work; a third of the sun
	/// quietly disappearing is a curiosity. They shouldn't get the same amount of screen.
	private var isMajor: Bool {
		circumstances.obscuration >= Constants.Eclipse.majorThreshold || circumstances.isCentral
	}

	private var coverage: String {
		circumstances.obscuration.formatted(.percent.precision(.fractionLength(0)))
	}

	private var title: Text {
		switch circumstances.kind {
		case .total: Text("Total solar eclipse")
		case .annular: Text("Annular solar eclipse")
		case .partial: Text("Partial solar eclipse")
		}
	}

	private var icon: String {
		switch circumstances.kind {
		case .total: "circle.fill"
		case .annular: "circle.circle"
		case .partial: "circle.righthalf.filled"
		}
	}

	var body: some View {
		Section {
			Group {
				if isMajor {
					majorRows
				} else {
					compactRow
				}
			}
			.environment(\.timeZone, location.timeZone)
		} header: {
			if isMajor {
				Text("Upcoming solar eclipse")
			}
		} footer: {
			if isMajor {
				// An app that tells someone to go and look at the sun owes them this.
				if circumstances.kind == .total {
					Text("Never look at the sun without certified eclipse glasses. Only during totality, when the sun is completely covered, is it safe to look with the naked eye.")
				} else {
					Text("Never look at the sun without certified eclipse glasses, even when it is almost entirely covered.")
				}
			}
		}
		.materialListRowBackground()
	}

	// MARK: - Compact treatment

	/// One line, in the same shape as the "Longest day" row: the kind of eclipse as the
	/// label, with the value tapping between when it is and how much it takes.
	private var compactRow: some View {
		Label {
			AdaptiveStack {
				ContentToggle { showContent in
					if showContent {
						Text("\(coverage) covered")
					} else {
						Text(circumstances.maximum, style: .date)
					}
				}
			} label: {
				title
			}
		} icon: {
			Image(systemName: icon)
		}
		.jumpToEclipse(circumstances.maximum, timeMachine: timeMachine)
	}

	// MARK: - Full treatment

	@ViewBuilder
	private var majorRows: some View {
		Label {
			AdaptiveStack {
				ContentToggle { showContent in
					if showContent {
						Text(circumstances.maximum, style: .date)
					} else {
						Text(eclipseFormatter.localizedString(
							for: circumstances.maximum.startOfDay,
							relativeTo: timeMachine.date.startOfDay
						))
					}
				}
			} label: {
				title
			}
		} icon: {
			Image(systemName: icon)
		}
		.jumpToEclipse(circumstances.maximum, timeMachine: timeMachine)

		Label {
			AdaptiveStack {
				Text("\(coverage) of the sun")
			} label: {
				Text("Maximum coverage")
			}
		} icon: {
			Image(systemName: "circle.lefthalf.filled")
		}

		if let centralDuration = circumstances.centralDuration {
			Label {
				AdaptiveStack {
					// Deliberately coarse. This figure comes from the difference between
					// two apparent radii within a few percent of each other, so it is the
					// least certain number here — quoting it to the second would claim a
					// precision the underlying theory can't support.
					Text(Duration.seconds(centralDuration).formatted(
						.units(allowed: [.minutes, .seconds], maximumUnitCount: 2)
					))
				} label: {
					if circumstances.kind == .total {
						Text("Totality lasts about")
					} else {
						Text("Annularity lasts about")
					}
				}
			} icon: {
				Image(systemName: "hourglass")
			}
		}

		Label {
			AdaptiveStack {
				Text(circumstances.firstContact, style: .time)
			} label: {
				Text("Eclipse begins")
			}
		} icon: {
			Image(systemName: "sunrise")
		}

		Label {
			AdaptiveStack {
				Text(circumstances.maximum, style: .time)
			} label: {
				Text("Maximum eclipse")
			}
		} icon: {
			Image(systemName: "sun.max")
		}

		Label {
			AdaptiveStack {
				Text(circumstances.lastContact, style: .time)
			} label: {
				Text("Eclipse ends")
			}
		} icon: {
			Image(systemName: "sunset")
		}

		// Below roughly ten degrees the sun is behind most rooftops and hills, which
		// changes the advice from "look up" to "find somewhere with a clear horizon".
		if circumstances.sunAltitudeAtMaximum < 10 {
			Label {
				AdaptiveStack {
					Text("\(Int(circumstances.sunAltitudeAtMaximum.rounded()))° above the horizon")
				} label: {
					Text("Low in the sky")
				}
			} icon: {
				Image(systemName: "mountain.2")
			}
		}
	}
}

private extension View {
	/// Matches the swipe-to-time-travel affordance the solstice and equinox rows carry.
	func jumpToEclipse(_ date: Date, timeMachine: TimeMachine) -> some View {
		swipeActions(edge: .leading) {
			Button {
				withAnimation {
					timeMachine.date = date
				}
			} label: {
				Label("Jump to date", systemImage: "clock.arrow.2.circlepath")
			}
		}
	}
}

#Preview("Total") {
	Form {
		EclipseOverview(
			circumstances: .init(
				kind: .total,
				obscuration: 1,
				magnitude: 1.038,
				firstContact: .now.addingTimeInterval(3600),
				maximum: .now.addingTimeInterval(7200),
				lastContact: .now.addingTimeInterval(10800),
				centralDuration: 63,
				sunAltitudeAtMaximum: 24.5
			),
			location: TemporaryLocation.placeholderLondon
		)
	}
	.withTimeMachine(.solsticeTimeMachine)
}

#Preview("Partial") {
	Form {
		EclipseOverview(
			circumstances: .init(
				kind: .partial,
				obscuration: 0.34,
				magnitude: 0.45,
				firstContact: .now.addingTimeInterval(3600),
				maximum: .now.addingTimeInterval(7200),
				lastContact: .now.addingTimeInterval(10800),
				centralDuration: nil,
				sunAltitudeAtMaximum: 32
			),
			location: TemporaryLocation.placeholderLondon
		)
	}
	.withTimeMachine(.solsticeTimeMachine)
}
