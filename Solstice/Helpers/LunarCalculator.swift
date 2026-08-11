//
//  LunarCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 11/08/2026.
//
//  What the moon is doing at a place on a day: when it rises and sets, how much of it is
//  lit, and where it is in the sky.
//
//  Positions come from `Ephemeris`. Illumination follows Meeus chapter 48; rising and
//  setting are solved directly rather than by Meeus's chapter 15 interpolation, because
//  the ephemeris already gives topocentric positions and sampling them is both simpler
//  and more robust near the awkward cases.
//

import CoreLocation
import Foundation

enum LunarCalculator {
	// MARK: - Public types

	/// The eight conventional phases, each a 45° slice of the lunation centred on the
	/// principal phase it is named for.
	enum Phase: String, CaseIterable, Hashable, Sendable {
		case new, waxingCrescent, firstQuarter, waxingGibbous
		case full, waningGibbous, lastQuarter, waningCrescent

		/// Whether the lit fraction is growing.
		var isWaxing: Bool {
			switch self {
			case .new, .waxingCrescent, .firstQuarter, .waxingGibbous: true
			case .full, .waningGibbous, .lastQuarter, .waningCrescent: false
			}
		}
	}

	/// The four phases that are instants rather than ranges, and so can be searched for.
	enum PrincipalPhase: Hashable, Sendable {
		case new, firstQuarter, full, lastQuarter

		/// Elongation from the sun, in degrees, that defines this phase.
		var elongation: Double {
			switch self {
			case .new: 0
			case .firstQuarter: 90
			case .full: 180
			case .lastQuarter: 270
			}
		}
	}

	struct Moon: Hashable, Sendable {
		let date: Date

		/// When the moon's upper limb clears the horizon, or `nil` on a day it does not
		/// rise at all.
		///
		/// A missing value here is ordinary, not an error. The moon rises roughly 50
		/// minutes later each day, so about once a lunation a calendar day contains no
		/// moonrise — or no moonset. Unlike the polar cases `NTSolar` handles, this
		/// happens at every latitude, every month.
		let moonrise: Date?
		let moonset: Date?

		/// Fraction of the moon's disc that is lit, 0...1.
		let illuminatedFraction: Double

		let phase: Phase

		/// Elongation from the sun in degrees, 0 at new moon and 180 at full. Drives the
		/// phase glyph, which needs the continuous value rather than the bucketed one.
		let elongation: Double

		/// Distance to the moon in kilometres.
		let distance: Double

		/// Whether the moon is above the horizon at `date`.
		let isUp: Bool
	}

	// MARK: - Public API

	static func moon(
		for date: Date,
		coordinate: CLLocationCoordinate2D,
		timeZone: TimeZone = .autoupdatingCurrent
	) -> Moon {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = timeZone
		let dayStart = calendar.startOfDay(for: date)

		let (moonrise, moonset) = riseAndSet(onDayStarting: dayStart, coordinate: coordinate)

		let jd = Ephemeris.julianDay(from: date)
		let jde = Ephemeris.julianEphemerisDay(fromJulianDay: jd)
		let illumination = illumination(jde: jde)
		let (_, _, distance) = Ephemeris.lunarPosition(jde: jde)

		return Moon(
			date: date,
			moonrise: moonrise,
			moonset: moonset,
			illuminatedFraction: illumination.fraction,
			phase: phase(forElongation: illumination.elongation),
			elongation: illumination.elongation,
			distance: distance,
			isUp: altitude(at: date, coordinate: coordinate) > 0
		)
	}

	/// The moon's altitude above the horizon in degrees, topocentric.
	static func altitude(at date: Date, coordinate: CLLocationCoordinate2D) -> Double {
		position(at: Ephemeris.julianDay(from: date), coordinate: coordinate).altitude
	}

	/// The next time the moon reaches a principal phase after `date`.
	static func nextPhaseEvent(_ phase: PrincipalPhase, after date: Date) -> Date? {
		let start = Ephemeris.julianDay(from: date)
		// Six-hour steps advance the elongation by about 3°, comfortably fine enough to
		// bracket a crossing without mistaking it for the 360° wrap.
		let step = 0.25
		let limit = Ephemeris.synodicMonth + 2

		var previous = start
		var previousOffset = elongationOffset(at: start, target: phase.elongation)
		var elapsed = step

		while elapsed <= limit {
			let jd = start + elapsed
			let offset = elongationOffset(at: jd, target: phase.elongation)

			// A genuine crossing steps a few degrees from negative to positive. The wrap
			// from +180 to −180 halfway round the lunation jumps by hundreds, so the
			// magnitude check keeps it from being mistaken for one.
			if previousOffset < 0, offset >= 0, abs(offset - previousOffset) < 90 {
				return Ephemeris.date(fromJulianDay: refineElongation(
					from: previous, to: jd, target: phase.elongation
				))
			}

			previous = jd
			previousOffset = offset
			elapsed += step
		}

		return nil
	}

	// MARK: - Illumination (Meeus chapter 48)

	private static func illumination(jde: Double) -> (fraction: Double, elongation: Double) {
		// Geometric longitudes are enough here: nutation shifts both bodies by the same
		// amount and cancels in the elongation, and aberration is far below the precision
		// an illuminated fraction is quoted to.
		let (sunLongitude, sunDistanceAU) = Ephemeris.solarPosition(jde: jde)
		let (moonLongitude, moonLatitude, moonDistance) = Ephemeris.lunarPosition(jde: jde)

		let sunDistance = sunDistanceAU * Ephemeris.astronomicalUnitKm

		// Geocentric elongation of the moon from the sun.
		let cosPsi = Ephemeris.clamped(
			cos(Ephemeris.radians(moonLatitude)) * cos(Ephemeris.radians(moonLongitude - sunLongitude))
		)
		let psi = acos(cosPsi)

		// Phase angle: the sun–moon–Earth angle. Note the moon is much nearer than the
		// sun, so this is nowhere near equal to 180° − elongation.
		let phaseAngle = atan2(
			sunDistance * sin(psi),
			moonDistance - sunDistance * cos(psi)
		)

		return (
			fraction: (1 + cos(phaseAngle)) / 2,
			elongation: Ephemeris.normalise(moonLongitude - sunLongitude)
		)
	}

	/// How far either side of an exact principal phase still counts as that phase — a
	/// little over half a day.
	private static let principalPhaseWindow = 7.5

	private static func phase(forElongation elongation: Double) -> Phase {
		// The four principal phases get a narrow window and the crescents and gibbous
		// phases take everything between. Splitting the lunation into eight equal 45°
		// slices instead would be simpler, but it would call a moon that is 68% lit
		// "first quarter" — a first quarter moon is half lit, and anyone looking up would
		// see the app was wrong.
		func isNear(_ target: Double) -> Bool {
			abs(Ephemeris.normalise(elongation - target + 180) - 180) <= principalPhaseWindow
		}

		if isNear(0) { return .new }
		if isNear(90) { return .firstQuarter }
		if isNear(180) { return .full }
		if isNear(270) { return .lastQuarter }

		switch elongation {
		case ..<90: return .waxingCrescent
		case ..<180: return .waxingGibbous
		case ..<270: return .waningGibbous
		default: return .waningCrescent
		}
	}

	/// Signed difference between the elongation at `jd` and a target, wrapped to
	/// −180...180 so it passes cleanly through zero at the crossing.
	private static func elongationOffset(at jd: Double, target: Double) -> Double {
		let jde = Ephemeris.julianEphemerisDay(fromJulianDay: jd)
		let elongation = illumination(jde: jde).elongation
		let difference = Ephemeris.normalise(elongation - target)
		return difference > 180 ? difference - 360 : difference
	}

	private static func refineElongation(from low: Double, to high: Double, target: Double) -> Double {
		var low = low
		var high = high

		for _ in 0 ..< 30 {
			let middle = (low + high) / 2
			if elongationOffset(at: middle, target: target) < 0 {
				low = middle
			} else {
				high = middle
			}
		}

		return (low + high) / 2
	}

	// MARK: - Rising and setting

	/// Refraction at the horizon, in degrees.
	private static let refraction = 34.0 / 60.0

	/// Altitude of the moon's *centre* at the moment its upper limb touches the horizon.
	///
	/// Meeus quotes `h₀ = 0.7275·π − 34′` for this, but that figure is for use with
	/// *geocentric* positions: the `0.7275·π` term exists to fold in parallax, which
	/// lowers the moon by nearly a degree near the horizon, along with its semidiameter.
	/// `Ephemeris` hands back topocentric positions, so parallax is already applied and
	/// applying it again would put moonrise out by the better part of two hours. What is
	/// left is refraction and the semidiameter, exactly as for the sun.
	private static func standardAltitude(topocentricDistance: Double) -> Double {
		let semidiameter = Ephemeris.degrees(
			asin(Ephemeris.clamped(Ephemeris.moonRadiusKm / topocentricDistance))
		)
		return -refraction - semidiameter
	}

	private static func position(
		at jd: Double,
		coordinate: CLLocationCoordinate2D
	) -> (altitude: Double, distance: Double) {
		let jde = Ephemeris.julianEphemerisDay(fromJulianDay: jd)
		let t = (jde - 2451545.0) / 36525.0

		let (nutationLongitude, nutationObliquity) = Ephemeris.nutation(t: t)
		let obliquity = Ephemeris.meanObliquity(t: t) + nutationObliquity

		let (longitude, latitude, distance) = Ephemeris.lunarPosition(jde: jde)
		let equatorial = Ephemeris.equatorial(
			longitude: longitude + nutationLongitude,
			latitude: latitude,
			obliquity: obliquity
		)

		let siderealTime = Ephemeris.apparentSiderealTime(
			jd: jd,
			nutationLongitude: nutationLongitude,
			obliquity: obliquity
		)
		let localSiderealTime = siderealTime + coordinate.longitude
		let observer = Ephemeris.observerVector(
			latitude: coordinate.latitude,
			localSiderealTime: localSiderealTime
		)

		let topocentric = Ephemeris.topocentric(
			rightAscension: equatorial.rightAscension,
			declination: equatorial.declination,
			distance: distance,
			observer: observer
		)

		let altitude = Ephemeris.altitude(
			declination: topocentric.declination,
			hourAngle: localSiderealTime - topocentric.rightAscension,
			latitude: coordinate.latitude
		)

		return (altitude, topocentric.distance)
	}

	/// How far the moon is above or below the altitude at which it rises. Positive means
	/// visible.
	private static func elevation(at jd: Double, coordinate: CLLocationCoordinate2D) -> Double {
		let (altitude, distance) = position(at: jd, coordinate: coordinate)
		return altitude - standardAltitude(topocentricDistance: distance)
	}

	/// Scans the 24 hours from `dayStart` for horizon crossings.
	///
	/// Ten-minute steps are comfortably finer than the moon's motion — it takes well over
	/// half an hour to cross its own diameter — so no crossing can hide between samples.
	private static func riseAndSet(
		onDayStarting dayStart: Date,
		coordinate: CLLocationCoordinate2D
	) -> (moonrise: Date?, moonset: Date?) {
		let start = Ephemeris.julianDay(from: dayStart)
		let step = 10.0 / 1440.0
		let steps = Int((1.0 / step).rounded())

		var moonrise: Date?
		var moonset: Date?

		var previousJD = start
		var previousElevation = elevation(at: start, coordinate: coordinate)

		for index in 1 ... steps {
			let jd = start + Double(index) * step
			let currentElevation = elevation(at: jd, coordinate: coordinate)

			if previousElevation < 0, currentElevation >= 0, moonrise == nil {
				moonrise = Ephemeris.date(fromJulianDay: refineCrossing(
					from: previousJD, to: jd, coordinate: coordinate
				))
			} else if previousElevation >= 0, currentElevation < 0, moonset == nil {
				moonset = Ephemeris.date(fromJulianDay: refineCrossing(
					from: previousJD, to: jd, coordinate: coordinate
				))
			}

			previousJD = jd
			previousElevation = currentElevation
		}

		return (moonrise, moonset)
	}

	private static func refineCrossing(
		from low: Double,
		to high: Double,
		coordinate: CLLocationCoordinate2D
	) -> Double {
		var low = low
		var high = high
		let startsBelow = elevation(at: low, coordinate: coordinate) < 0

		for _ in 0 ..< 25 {
			let middle = (low + high) / 2
			if (elevation(at: middle, coordinate: coordinate) < 0) == startsBelow {
				low = middle
			} else {
				high = middle
			}
		}

		return (low + high) / 2
	}
}
