//
//  LocationListRow.swift
//  Solstice
//
//  Created by Daniel Eden on 12/02/2023.
//

import SwiftUI
import Solar
import Suite

struct LocationListRow<Location: ObservableLocation>: View {
	@EnvironmentObject private var timeMachine: TimeMachine
	var location: Location
	
	@FocusState private var focused: Bool
	
	@State private var showRemainingDaylight = false
	
	private var solar: Solar? {
		Solar(for: timeMachine.date, coordinate: location.coordinate)
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
		if let solar {
			VStack(alignment: .trailing) {
				Text(Duration.seconds(solar.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
				#if os(iOS)
					.font(.headline)
				#endif
				Text(solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)...solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone))
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
			
			if let solar {
				Group {
					Text(Duration.seconds(solar.daylightDuration).formatted(.units(allowed: [.hours, .minutes])))
						.font(.headline)
						.contentTransition(.numericText())
					Text(solar.safeSunrise.withTimeZoneAdjustment(for: location.timeZone)...solar.safeSunset.withTimeZoneAdjustment(for: location.timeZone))
						.font(.footnote.weight(.light))
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
				locationTitleLabel
				locationSubtitleLabel
			}
			.animation(.default, value: location.title)
			.animation(.default, value: location.subtitle)
			
			Spacer()
			
			trailingContent
		}
		#if os(iOS)
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
		.focusEffectDisabled()
		.focused($focused)
		.overlay {
			if focused {
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(.clear)
					.strokeBorder(.tint, lineWidth: 3)
			}
		}
		#endif
		#endif
	}
	
	@ViewBuilder
	var locationTitleLabel: some View {
		HStack {
			if location is CurrentLocation {
				Image(systemName: "location")
					.imageScale(.small)
					.foregroundStyle(.secondary)
					.symbolVariant(.fill)
			}
			
			Group {
				if let title = location.title {
					Text(verbatim: title)
						.id(location.title)
				} else {
					Text("Current location")
				}
			}
			.transition(.blurReplace)
			.lineLimit(2)
		}
		.font(.headline)
		#if os(iOS)
		.fontWeight(.bold)
		#endif
	}
	
	@ViewBuilder
	var locationSubtitleLabel: some View {
		if let subtitle,
			 !subtitle.isEmpty {
			Text(subtitle)
				.id(subtitle)
				.foregroundStyle(.secondary)
				.transition(.blurReplace)
		}
	}
}

#Preview {
	List {
		LocationListRow(location: TemporaryLocation.placeholderLondon)
	}
	.environmentObject(TimeMachine.preview)
}
