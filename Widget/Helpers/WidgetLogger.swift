//
//  WidgetLogger.swift
//  Solstice
//
//  Created by Daniel Eden on 11/02/2026.
//

import Foundation
import OSLog

// MARK: - OSLog Loggers
enum WidgetLogger {
	static let timeline = Logger(subsystem: "me.daneden.Solstice", category: "timeline")
	static let location = Logger(subsystem: "me.daneden.Solstice", category: "location")
	static let widget = Logger(subsystem: "me.daneden.Solstice", category: "widget")
}

// MARK: - Persistent Log Entry
struct WidgetLogEntry: Codable {
	enum Category: String, Codable {
		case timeline, location, error
	}

	let date: Date
	let category: Category
	let message: String
	let metadata: [String: String]?
}

// MARK: - Persistent Log Store
enum WidgetLogStore {
	private static let maxEntries = 500
	private static let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

	private static var logFileURL: URL? {
		FileManager.default
			.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier)?
			.appendingPathComponent(Constants.widgetLogFileName)
	}

	static func log(_ category: WidgetLogEntry.Category, _ message: String, metadata: [String: String]? = nil) {
		let entry = WidgetLogEntry(
			date: Date(),
			category: category,
			message: message,
			metadata: metadata
		)

		var entries = readEntries()
		entries.append(entry)
		entries = pruned(entries)
		writeEntries(entries)
	}

	static func readEntries() -> [WidgetLogEntry] {
		guard let url = logFileURL,
			  let data = try? Data(contentsOf: url) else {
			return []
		}
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		guard let entries = try? decoder.decode([WidgetLogEntry].self, from: data) else {
			return []
		}
		return entries
	}

	static func clearEntries() {
		writeEntries([])
	}

	// MARK: - Private

	private static func writeEntries(_ entries: [WidgetLogEntry]) {
		guard let url = logFileURL else { return }
		do {
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .iso8601
			let data = try encoder.encode(entries)
			try data.write(to: url, options: .atomic)
		} catch {
			WidgetLogger.widget.error("Failed to write log file: \(error.localizedDescription)")
		}
	}

	private static func pruned(_ entries: [WidgetLogEntry]) -> [WidgetLogEntry] {
		let cutoff = Date().addingTimeInterval(-maxAge)
		var result = entries.filter { $0.date > cutoff }

		let removedCount = entries.count - result.count
		if removedCount > 0 {
			WidgetLogger.widget.debug("Pruned \(removedCount) expired log entries")
		}

		if result.count > maxEntries {
			let overflow = result.count - maxEntries
			result = Array(result.dropFirst(overflow))
			WidgetLogger.widget.debug("Pruned \(overflow) overflow log entries")
		}

		return result
	}
}
