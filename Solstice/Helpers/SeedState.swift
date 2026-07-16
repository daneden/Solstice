//
//  SeedState.swift
//  Solstice
//
//  Created by Daniel Eden on 16/07/2026.
//

import Foundation

/// Tracks whether the default locations have ever been seeded for this iCloud
/// account. Stored in the ubiquitous key-value store so the fact syncs across a
/// user's devices — a per-device flag can't prevent a freshly-set-up second
/// device from re-seeding defaults the user already deleted elsewhere.
enum SeedState {
	private static let didSeedKey = "didSeedDefaultLocations"

	private static var store: NSUbiquitousKeyValueStore {
		.default
	}

	static var didSeedDefaultLocations: Bool {
		get { store.bool(forKey: didSeedKey) }
		set {
			store.set(newValue, forKey: didSeedKey)
			store.synchronize()
		}
	}

	/// Pulls the latest value from iCloud (best-effort) before the seed gate reads it.
	static func synchronize() {
		store.synchronize()
	}
}
