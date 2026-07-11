#!/usr/bin/env swift
//
//  validate-localizations.swift
//  Solstice
//
//  Fails if any String Catalog (.xcstrings) has untranslated strings for a
//  language the project ships. Intended to gate App Store distribution
//  archives from Xcode Cloud (see ci_pre_xcodebuild.sh), but runnable locally:
//
//      swift ci_scripts/validate-localizations.swift
//
//  Policy:
//    - The set of required languages is derived from the catalogs themselves
//      (the union of every non-source locale that appears in any catalog), so
//      adding a language to the project automatically extends coverage checks.
//    - A string fails when, for a required language, it is in the "new" state
//      or has no localization entry at all.
//    - By default "machine_translated" and "needs_review" count as shippable,
//      because the project intentionally ships machine translations.
//    - Set LOCALIZATION_STRICT=1 to require human "translated" state instead,
//      which additionally fails "machine_translated" and "needs_review".
//    - Keys marked "shouldTranslate": false and "stale" keys are skipped.
//

import Foundation

// MARK: - Configuration

let strict = ["1", "true", "yes"].contains(
	(ProcessInfo.processInfo.environment["LOCALIZATION_STRICT"] ?? "").lowercased()
)

let acceptableStates: Set<String> = strict
	? ["translated"]
	: ["translated", "machine_translated", "needs_review"]

/// Directories that never contain first-party, shippable catalogs.
let excludedPathFragments = [
	"/Frameworks/", "/.build/", "/DerivedData/", "/Pods/",
	"/Carthage/", "/.git/", "/build/",
]

// MARK: - Locate the repository root

func repositoryRoot() -> URL {
	let env = ProcessInfo.processInfo.environment
	if let ciPath = env["CI_PRIMARY_REPOSITORY_PATH"], !ciPath.isEmpty {
		return URL(fileURLWithPath: ciPath, isDirectory: true)
	}
	// This file lives at <root>/ci_scripts/validate-localizations.swift.
	let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
	let candidate = scriptDir.deletingLastPathComponent()
	if FileManager.default.fileExists(atPath: candidate.appendingPathComponent(".git").path)
		|| FileManager.default.fileExists(atPath: candidate.appendingPathComponent("ci_scripts").path)
	{
		return candidate
	}
	return URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
}

let root = repositoryRoot()

// MARK: - Discover String Catalogs

func discoverCatalogs(under root: URL) -> [URL] {
	let fm = FileManager.default
	guard let enumerator = fm.enumerator(
		at: root,
		includingPropertiesForKeys: nil,
		options: [.skipsHiddenFiles]
	) else { return [] }

	var catalogs: [URL] = []
	for case let url as URL in enumerator where url.pathExtension == "xcstrings" {
		let path = url.path
		if excludedPathFragments.contains(where: { path.contains($0) }) { continue }
		catalogs.append(url)
	}
	return catalogs.sorted { $0.path < $1.path }
}

let catalogs = discoverCatalogs(under: root)

guard !catalogs.isEmpty else {
	FileHandle.standardError.write(Data(
		"error: no .xcstrings catalogs found under \(root.path)\n".utf8
	))
	exit(1)
}

// MARK: - Model

struct Catalog {
	let url: URL
	let sourceLanguage: String
	let strings: [String: [String: Any]]
}

func loadCatalog(_ url: URL) -> Catalog? {
	guard let data = try? Data(contentsOf: url),
	      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
	      let strings = json["strings"] as? [String: [String: Any]]
	else { return nil }
	let source = json["sourceLanguage"] as? String ?? "en"
	return Catalog(url: url, sourceLanguage: source, strings: strings)
}

let loaded = catalogs.compactMap(loadCatalog)

// MARK: - Required languages (union of every non-source locale seen)

var sourceLanguages = Set<String>()
var seenLanguages = Set<String>()
for catalog in loaded {
	sourceLanguages.insert(catalog.sourceLanguage)
	for (_, entry) in catalog.strings {
		if let locs = entry["localizations"] as? [String: Any] {
			for lang in locs.keys {
				seenLanguages.insert(lang)
			}
		}
	}
}

let requiredLanguages = seenLanguages.subtracting(sourceLanguages).sorted()

guard !requiredLanguages.isEmpty else {
	print("No non-source localizations found; nothing to validate.")
	exit(0)
}

// MARK: - Validation

/// Returns the state strings for a localization entry: one for a plain
/// stringUnit, or one per plural/device case for a "variations" entry.
/// Returns nil when the entry is malformed (treated as a violation).
func states(in localization: [String: Any]) -> [String]? {
	if let unit = localization["stringUnit"] as? [String: Any] {
		return [unit["state"] as? String ?? "new"]
	}
	// App Shortcut phrases store alternative phrasings in a "stringSet".
	if let set = localization["stringSet"] as? [String: Any] {
		return [set["state"] as? String ?? "new"]
	}
	if let variations = localization["variations"] as? [String: Any] {
		var result: [String] = []
		for (_, cases) in variations {
			guard let cases = cases as? [String: Any] else { return nil }
			for (_, caseValue) in cases {
				guard let caseDict = caseValue as? [String: Any],
				      let unit = caseDict["stringUnit"] as? [String: Any]
				else { return nil }
				result.append(unit["state"] as? String ?? "new")
			}
		}
		return result.isEmpty ? nil : result
	}
	return nil
}

struct Violation {
	let catalog: String
	let language: String
	let key: String
	let reason: String
}

var violations: [Violation] = []

for catalog in loaded {
	let relativePath = catalog.url.path
		.replacingOccurrences(of: root.path + "/", with: "")

	for (key, entry) in catalog.strings {
		if entry["shouldTranslate"] as? Bool == false { continue }
		if entry["extractionState"] as? String == "stale" { continue }

		let localizations = entry["localizations"] as? [String: Any] ?? [:]

		// A key whose source value is empty (e.g. NSHumanReadableCopyright,
		// supplied from build settings) has nothing to translate.
		let sourceValue: String
		if let srcLoc = localizations[catalog.sourceLanguage] as? [String: Any],
		   let unit = srcLoc["stringUnit"] as? [String: Any],
		   let value = unit["value"] as? String
		{
			sourceValue = value
		} else {
			sourceValue = key
		}
		if sourceValue.isEmpty { continue }

		for language in requiredLanguages where language != catalog.sourceLanguage {
			guard let localization = localizations[language] as? [String: Any] else {
				violations.append(Violation(
					catalog: relativePath, language: language, key: key,
					reason: "no translation"
				))
				continue
			}
			guard let stateList = states(in: localization) else {
				violations.append(Violation(
					catalog: relativePath, language: language, key: key,
					reason: "malformed localization"
				))
				continue
			}
			let bad = stateList.filter { !acceptableStates.contains($0) }
			if !bad.isEmpty {
				violations.append(Violation(
					catalog: relativePath, language: language, key: key,
					reason: "state '\(Set(bad).sorted().joined(separator: ", "))'"
				))
			}
		}
	}
}

// MARK: - Report

let mode = strict ? "strict (human 'translated' required)" : "lenient (machine translations allowed)"
print("Localization gate: \(mode)")
print("Catalogs checked: \(loaded.count)")
print("Required languages: \(requiredLanguages.joined(separator: ", "))")

if violations.isEmpty {
	print("✓ All strings are translated for every required language.")
	exit(0)
}

/// Group counts by catalog + language, and show a capped set of examples.
var counts: [String: Int] = [:]
for v in violations {
	counts["\(v.catalog) [\(v.language)]", default: 0] += 1
}

print("")
print("✗ Found \(violations.count) untranslated string(s):")
for key in counts.keys.sorted() {
	print("  \(key): \(counts[key]!)")
}

let exampleLimit = 20
print("")
print("Examples (up to \(exampleLimit)):")
for v in violations.prefix(exampleLimit) {
	// Emit as an Xcode-recognisable error line.
	FileHandle.standardError.write(Data(
		"error: [\(v.catalog)] \(v.language): \"\(v.key)\" — \(v.reason)\n".utf8
	))
}

if violations.count > exampleLimit {
	print("… and \(violations.count - exampleLimit) more.")
}

exit(1)
