//
//  LocationListRow.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import Suite
import SwiftUI
import TimeMachine

struct LocationListRow<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine: TimeMachine
	@Environment(LocationNameResolver.self) private var nameResolver: LocationNameResolver?
	var location: Location

	/// Localized display name via the resolver when available (falls back to the
	/// stored values on targets/previews where the resolver isn't injected).
	private var resolvedName: (title: String?, subtitle: String?) {
		nameResolver?.displayName(for: location) ?? (location.title, location.subtitle)
	}

	@FocusState private var focused: Bool

	@State private var showRemainingDaylight = false

	var headingFontWeight: Font.Weight = .medium

	private var solar: NTSolar? {
		NTSolar(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
	}

	private var isCurrentLocation: Bool {
		location is CurrentLocation
	}

	private var subtitle: String? {
		if location is CurrentLocation, resolvedName.title == nil {
			return "—"
		} else {
			return resolvedName.subtitle
		}
	}

	@ViewBuilder
	var trailingContent: some View {
		if let solar {
			VStack(alignment: .trailing) {
				Text(Duration.seconds(solar.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
				#if os(iOS)
					.font(.headline.weight(headingFontWeight))
				#endif

				let sunrise = solar.safeSunrise
				let sunset = solar.safeSunset

				if sunrise < sunset {
					Text(sunrise ... sunset)
						.foregroundStyle(.secondary)
						.font(.subheadline)
				}
			}
			.contentTransition(.identity)
			.environment(\.timeZone, location.timeZone)
		}
	}

	var body: some View {
		#if os(watchOS)
			VStack(alignment: .leading) {
				HStack {
					locationTitleLabel

					if !(location is CurrentLocation) {
						Spacer()
						Text(timeMachine.date, style: .time)
							.environment(\.timeZone, location.timeZone)
							.foregroundStyle(.secondary)
							.contentTransition(.numericText())
					}
				}

				if let solar {
					Group {
						Text(Duration.seconds(solar.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
							.font(.headline)
							.contentTransition(.numericText())
						Text(solar.safeSunrise ... solar.safeSunset)
							.font(.footnote)
							.foregroundStyle(.secondary)
							.contentTransition(.numericText())
					}
				}
			}
			.animation(.default, value: resolvedName.title)
			.animation(.default, value: resolvedName.subtitle)
			.animation(.default, value: timeMachine.date)
			.shadow(radius: 4, x: 0, y: 2)
			.environment(\.timeZone, location.timeZone)
		#else
			HStack {
				VStack(alignment: .leading, spacing: 2) {
					Group {
						locationTitleLabel
						locationSubtitleLabel
					}
					.lineLimit(2)
				}
				.animation(.default, value: location.title)
				.animation(.default, value: location.subtitle)

				Spacer()

				trailingContent
			}
		#endif
	}

	var locationTitleLabel: some View {
		HStack(spacing: 4) {
			if location is CurrentLocation {
				Image(systemName: "location")
					.imageScale(.small)
					.foregroundStyle(.secondary)
					.symbolVariant(.fill)
			}

			Text(resolvedName.title ?? String(localized: "Current Location"))
				.contentTransition(.numericText())
				.lineLimit(2)
		}
		.font(.headline.weight(headingFontWeight))
	}

	@ViewBuilder
	var locationSubtitleLabel: some View {
		if let subtitle,
		   !subtitle.isEmpty
		{
			Text(subtitle)
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.transition(.blurReplace)
		}
	}
}

#Preview {
	List {
		LocationListRow(location: TemporaryLocation.placeholderLondon)
	}
	.withTimeMachine(.solsticeTimeMachine)
}
