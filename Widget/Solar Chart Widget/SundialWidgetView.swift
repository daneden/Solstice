//
//  SolarChartWidgetView 2.swift
//  Solstice
//
//  Created by Daniel Eden on 09/10/2025.
//

import SwiftUI
import WidgetKit
import Suite

struct SundialWidgetView: SolsticeWidgetView {
	@Environment(\.widgetFamily) private var widgetFamily
	@Environment(\.widgetContentMargins) private var widgetContentMargins
	
	@State private var headerSize: CGSize = .zero
	
	var entry: SolsticeWidgetTimelineEntry
	
	var isSmallWidget: Bool {
		if widgetFamily == .systemSmall {
			return true
		}
		
		return false
	}
	
	@ViewBuilder
	private var smallWidgetHeader: some View {
		HStack {
			Label("Solstice", image: .solstice)
				.labelStyle(CompactLabelStyle())
			
			Spacer()
			
			if let title = location?.title {
				Label {
					Text(title)
				} icon: {
					if location?.isRealLocation == true {
						Image(systemName: "location")
							.imageScale(.small)
							.symbolVariant(.fill)
					}
				}
				.labelStyle(CompactLabelStyle(spacing: 2, reverseOrder: true))
				.foregroundStyle(.secondary)
			}
		}
		.lineLimit(1)
		.allowsTightening(true)
	}
	
	@ViewBuilder
	private var smallWidgetFooter: some View {
		HStack {
			if let sunrise = solar?.sunrise,
				 let sunset = solar?.sunset {
				Text(sunrise...sunset)
			}
			
			Spacer(minLength: 8)
			
			if let duration = solar?.daylightDuration {
				Text(Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
			}
		}
		.lineLimit(1)
		.textScale(.secondary)
	}
	
	@ViewBuilder
	private var smallWidgetLabels: some View {
		VStack {
			smallWidgetHeader
			
			Spacer()
			
			smallWidgetFooter
		}
		.font(.caption2)
		
		.lineLimit(1)
	}
	
	var body: some View {
		Group {
			if let location {
				VStack {
					smallWidgetHeader
						.font(isSmallWidget ? .caption2 : .footnote)
						.textScale(isSmallWidget ? .secondary : .default)
						.readSize($headerSize)
					
					CircularSolarChart(date: entry.date, location: location)
						.labelsVisibility(isSmallWidget ? .hidden : .automatic)
					
					if isSmallWidget {
						smallWidgetFooter
							.font(.caption2)
					} else {
						Color.clear.frame(height: headerSize.height)
					}
				}
				.containerBackground(for: .widget) {
					solar?.view.opacity(0.15)
				}
			} else if needsReconfiguration {
				WidgetNeedsReconfigurationView()
					.containerBackground(.background, for: .widget)
			} else if shouldShowPlaceholder {
				SundialWidgetView(entry: .placeholder)
					.redacted(reason: .placeholder)
			} else {
				WidgetMissingLocationView()
					.containerBackground(.background, for: .widget)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

fileprivate struct AdaptiveLabelContainer<Content: View>: View {
	@Environment(\.widgetRenderingMode) private var renderingMode
	
	var padding: CGFloat = 4
	
	@ViewBuilder
	var content: Content
	
	var body: some View {
		content
			.if(renderingMode == .fullColor) { content in
				content
					.padding(padding)
					.padding(.horizontal, padding / 2)
					.background(.regularMaterial, in: .containerRelative)
					.padding(padding * -1)
					.padding(.horizontal, padding * -0.5)
			}
	}
}

#if !os(macOS)
#Preview(as: .systemLarge) {
	SundialWidget()
} timeline: {
	SolsticeWidgetTimelineEntry(date: .now, location: .proxiedToTimeZone)
}
#endif
