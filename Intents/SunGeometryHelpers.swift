//
//  SunGeometryHelpers.swift
//  Solstice
//
//  Created by Daniel Eden on 24/04/2026.
//

import Foundation
import AppIntents
import CoreLocation

// MARK: - Location Resolution

/// Resolves a `LocationAppEntity?` parameter from a sun-geometry App Intent
/// into a concrete coordinate + timezone pair, falling back to the device's
/// current location when the entity is nil or represents the current location.
func resolveSunGeometryLocation(_ entity: LocationAppEntity?) async throws -> (coordinate: CLLocationCoordinate2D, timeZone: TimeZone) {
	if let entity, !entity.isCurrentLocation {
		let tz = entity.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .autoupdatingCurrent
		return (CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude), tz)
	}

	let location = try await CurrentLocation.fetchCurrentLocation()
	let tz = await reverseGeocodedTimeZone(for: location) ?? .autoupdatingCurrent
	return (location.coordinate, tz)
}

private let sunGeometryGeocoder = CLGeocoder()

private func reverseGeocodedTimeZone(for location: CLLocation) async -> TimeZone? {
	do {
		let placemarks = try await sunGeometryGeocoder.reverseGeocodeLocation(location)
		return placemarks.first?.timeZone
	} catch {
		return nil
	}
}

// MARK: - Angular Math

/// Returns the signed angular difference `to - from` wrapped into `-180...180`.
/// Positive = `to` is clockwise from `from`; negative = counterclockwise.
func signedAngularDifference(from: Double, to: Double) -> Double {
	var delta = (to - from).truncatingRemainder(dividingBy: 360.0)
	if delta > 180 {
		delta -= 360
	} else if delta <= -180 {
		delta += 360
	}
	return delta
}

// MARK: - Sun Position Entity

/// Transient entity exposing both altitude and azimuth for the sun at a point
/// in time. Used as the return value of `GetSunPositionAtTime` so both
/// properties are individually available as magic variables in Shortcuts.
struct SunPositionEntity: TransientAppEntity {
	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(name: "Sun Position")
	}

	@Property(title: "Altitude")
	var altitude: Measurement<UnitAngle>

	@Property(title: "Azimuth")
	var azimuth: Measurement<UnitAngle>

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "Sun Position",
			subtitle: "Altitude \(altitude.formatted()), Azimuth \(azimuth.formatted())"
		)
	}

	init() {
		self.altitude = Measurement(value: 0, unit: .degrees)
		self.azimuth = Measurement(value: 0, unit: .degrees)
	}

	init(altitudeDegrees: Double, azimuthDegrees: Double) {
		self.altitude = Measurement(value: altitudeDegrees, unit: .degrees)
		self.azimuth = Measurement(value: azimuthDegrees, unit: .degrees)
	}
}

// MARK: - Crossing Direction Enums

enum AltitudeCrossingDirection: String, AppEnum {
	case rising
	case falling
	case either

	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(name: "Altitude Direction")
	}

	static var caseDisplayRepresentations: [AltitudeCrossingDirection: DisplayRepresentation] = [
		.rising: "Rising",
		.falling: "Falling",
		.either: "Either",
	]
}

enum AzimuthCrossingDirection: String, AppEnum {
	case clockwise
	case counterclockwise
	case either

	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(name: "Azimuth Direction")
	}

	static var caseDisplayRepresentations: [AzimuthCrossingDirection: DisplayRepresentation] = [
		.clockwise: "Clockwise",
		.counterclockwise: "Counterclockwise",
		.either: "Either",
	]
}

// MARK: - Crossing Search

private let crossingSearchWindow: TimeInterval = 24 * 60 * 60
private let crossingSampleInterval: TimeInterval = 60
private let crossingBisectionPrecision: TimeInterval = 1

/// Finds the next time the sun's altitude crosses `targetDegrees` in the
/// specified direction, within 24 hours of `start`. Returns `nil` if no such
/// crossing exists in the window.
///
/// The sun's altitude is a smooth function of time, so we sample at a coarse
/// interval until we see a sign change in `altitude - target` that matches
/// the direction, then bisect within the bracket.
func findNextAltitudeCrossing(
	targetDegrees: Double,
	direction: AltitudeCrossingDirection,
	start: Date,
	coordinate: CLLocationCoordinate2D,
	timeZone: TimeZone
) -> Date? {
	guard let solar = NTSolar(for: start, coordinate: coordinate, timeZone: timeZone) else {
		return nil
	}

	let end = start.addingTimeInterval(crossingSearchWindow)
	let evaluate: (Date) -> Double = { solar.altitude(at: $0) - targetDegrees }

	var t0 = start
	var v0 = evaluate(t0)

	while t0 < end {
		let t1 = min(t0.addingTimeInterval(crossingSampleInterval), end)
		let v1 = evaluate(t1)

		let matchesDirection: Bool = {
			switch direction {
			case .rising: return v0 < 0 && v1 >= 0
			case .falling: return v0 > 0 && v1 <= 0
			case .either: return (v0 < 0 && v1 > 0) || (v0 > 0 && v1 < 0) || v1 == 0
			}
		}()

		if matchesDirection {
			return bisect(low: t0, high: t1, lowValue: v0, evaluate: evaluate)
		}

		t0 = t1
		v0 = v1
	}

	return nil
}

/// Finds the next time the sun's azimuth crosses `targetDegrees` in the
/// specified direction, within 24 hours of `start`. Returns `nil` if no such
/// crossing occurs.
///
/// Azimuth is discontinuous at 0°/360°; we operate on the signed angular
/// difference (`azimuth - target`, wrapped to `-180...180`) so that a
/// zero-crossing in this signed diff corresponds to an actual crossing of
/// the target bearing. Samples bracketing the wrap discontinuity (|Δ| > 180°)
/// are skipped.
func findNextAzimuthCrossing(
	targetDegrees: Double,
	direction: AzimuthCrossingDirection,
	start: Date,
	coordinate: CLLocationCoordinate2D,
	timeZone: TimeZone
) -> Date? {
	guard let solar = NTSolar(for: start, coordinate: coordinate, timeZone: timeZone) else {
		return nil
	}

	let end = start.addingTimeInterval(crossingSearchWindow)
	let evaluate: (Date) -> Double = { signedAngularDifference(from: targetDegrees, to: solar.azimuth(at: $0)) }

	var t0 = start
	var v0 = evaluate(t0)

	while t0 < end {
		let t1 = min(t0.addingTimeInterval(crossingSampleInterval), end)
		let v1 = evaluate(t1)

		// Skip samples straddling the ±180° wrap discontinuity.
		if abs(v1 - v0) > 180 {
			t0 = t1
			v0 = v1
			continue
		}

		let matchesDirection: Bool = {
			switch direction {
			case .clockwise: return v0 < 0 && v1 >= 0
			case .counterclockwise: return v0 > 0 && v1 <= 0
			case .either: return (v0 < 0 && v1 > 0) || (v0 > 0 && v1 < 0) || v1 == 0
			}
		}()

		if matchesDirection {
			return bisect(low: t0, high: t1, lowValue: v0, evaluate: evaluate)
		}

		t0 = t1
		v0 = v1
	}

	return nil
}

/// Bisect over `[low, high]` to find the time where `evaluate` crosses zero.
/// Assumes `lowValue` and `evaluate(high)` have opposite signs (or `lowValue == 0`).
private func bisect(
	low: Date,
	high: Date,
	lowValue: Double,
	evaluate: (Date) -> Double
) -> Date {
	var lo = low
	var hi = high
	var loVal = lowValue

	while hi.timeIntervalSince(lo) > crossingBisectionPrecision {
		let mid = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
		let midVal = evaluate(mid)
		if midVal == 0 {
			return mid
		}
		if (loVal < 0 && midVal < 0) || (loVal > 0 && midVal > 0) {
			lo = mid
			loVal = midVal
		} else {
			hi = mid
		}
	}

	return lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
}
