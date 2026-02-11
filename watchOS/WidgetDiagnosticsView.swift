//
//  WidgetDiagnosticsView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 11/02/2026.
//

import SwiftUI

struct WidgetDiagnosticsView: View {
	@State private var entries: [WidgetLogEntry] = []

	private var timelineGenerations: [WidgetLogEntry] {
		entries.filter { $0.category == .timeline && $0.message.contains("entries generated") }
	}

	private var lastGenerationTime: Date? {
		timelineGenerations.last?.date
	}

	private var averageEntryCount: Double? {
		let counts = timelineGenerations.compactMap { entry in
			entry.metadata?["count"].flatMap(Double.init)
		}
		guard !counts.isEmpty else { return nil }
		return counts.reduce(0, +) / Double(counts.count)
	}

	var body: some View {
		List {
			Section("Summary") {
				LabeledContent("Total generations", value: "\(timelineGenerations.count)")
				if let lastGenerationTime {
					LabeledContent("Last generation") {
						Text(lastGenerationTime, style: .relative)
					}
				}
				if let averageEntryCount {
					LabeledContent("Avg entries", value: String(format: "%.0f", averageEntryCount))
				}
				LabeledContent("Total log entries", value: "\(entries.count)")
			}

			Section {
				if entries.isEmpty {
					Text("No log entries")
						.foregroundStyle(.secondary)
				} else {
					ForEach(entries.reversed().prefix(100), id: \.date) { entry in
						VStack(alignment: .leading, spacing: 2) {
							HStack {
								categoryBadge(entry.category)
								Text(entry.date, style: .relative)
									.font(.caption2)
									.foregroundStyle(.secondary)
							}
							Text(entry.message)
								.font(.caption)
							if let metadata = entry.metadata, !metadata.isEmpty {
								Text(metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))
									.font(.caption2)
									.foregroundStyle(.secondary)
									.lineLimit(2)
							}
						}
					}
				}
			} header: {
				Text("Recent Events")
			}

			Section {
				Button("Clear Logs", role: .destructive) {
					WidgetLogStore.clearEntries()
					entries = []
				}
			}
		}
		.navigationTitle("Widget Logs")
		.onAppear {
			entries = WidgetLogStore.readEntries()
		}
	}

	@ViewBuilder
	private func categoryBadge(_ category: WidgetLogEntry.Category) -> some View {
		let (label, color): (String, Color) = switch category {
		case .timeline: ("TL", .blue)
		case .location: ("LOC", .green)
		case .error: ("ERR", .red)
		}

		Text(label)
			.font(.system(.caption2, design: .monospaced, weight: .bold))
			.foregroundStyle(color)
	}
}
