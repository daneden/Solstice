//
//  LocationListRow.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import SunKit
import Suite
import TimeMachine

struct LocationListRow<Location: ObservableLocation>: View {
	@Environment(\.timeMachine) private var timeMachine: TimeMachine
	var location: Location

	@FocusState private var focused: Bool

	@State private var showRemainingDaylight = false

	var headingFontWeight: Font.Weight = .medium

	private var sun: Sun? {
		Sun(for: timeMachine.date, coordinate: location.coordinate)
	}
	
	private var isCurrentLocation: Bool {
		location is CurrentLocation
	}
	
	private var subtitle: String? {
		if location is CurrentLocation && location.title == nil {
			return "—"
		} else {
			return location.subtitle
		}
	}
	
	@ViewBuilder
	var trailingContent: some View {
		if let sun {
			VStack(alignment: .trailing) {
				Text(Duration.seconds(sun.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
				#if os(iOS)
					.font(.headline.weight(headingFontWeight))
				#endif
				Text(sun.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)...sun.safeSunset.withTimeZoneAdjustment(for: location.timeZone))
					.foregroundStyle(.secondary)
			}
			.contentTransition(.identity)
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
			
			if let sun {
				Group {
					Text(Duration.seconds(sun.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
						.font(.headline)
						.contentTransition(.numericText())
					Text(sun.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)...sun.safeSunset.withTimeZoneAdjustment(for: location.timeZone))
						.font(.footnote)
						.foregroundStyle(.secondary)
						.contentTransition(.numericText())
				}
			}
		}
		.animation(.default, value: location.title)
		.animation(.default, value: location.subtitle)
		.animation(.default, value: timeMachine.date)
		.shadow(radius: 4, x: 0, y: 2)
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
	
	@ViewBuilder
	var locationTitleLabel: some View {
		HStack(spacing: 4) {
			if location is CurrentLocation {
				Image(systemName: "location")
					.imageScale(.small)
					.foregroundStyle(.secondary)
					.symbolVariant(.fill)
			}
			
			Text(location.title ?? "Current location")
				.contentTransition(.numericText())
				.lineLimit(2)
		}
		.font(.headline.weight(headingFontWeight))
	}
	
	@ViewBuilder
	var locationSubtitleLabel: some View {
		if let subtitle,
			 !subtitle.isEmpty {
			Text(subtitle)
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
