//
//  EclipseCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 11/08/2026.
//
//  Local circumstances for solar eclipses.
//
//  Positions of the sun and moon come from `Ephemeris`, which holds the Meeus series and
//  the coordinate machinery. What lives here is only the eclipse geometry: finding the
//  lunations where a shadow reaches the Earth, and working out what an observer at one
//  place sees of it.
//
//  Accuracy, checked against NASA's published circumstances:
//
//  - Contact times land within about half a minute. Meeus's truncated lunar series is
//    good to roughly 10 arcseconds, and the moon closes on the sun at about half an
//    arcsecond per second of time, so half a minute is the floor for this class of
//    method rather than something to tune away.
//  - Obscuration is good to well under a percent, and is the figure the UI leans on.
//  - Duration of totality is the weakest number, at a few percent. It depends on the
//    *difference* between the two apparent radii — about 53 arcseconds out of roughly
//    960 — so the same 10 arcsecond uncertainty that barely moves obscuration moves
//    this by several seconds. Present it as an approximation, not to the second.
//

import CoreLocation
import Foundation

enum EclipseCalculator {
	// MARK: - Public types

	enum Kind: Hashable, Sendable {
		/// The moon covers part of the sun's disc.
		case partial
		/// The moon is centred on the sun but too distant to cover it, leaving a ring.
		case annular
		/// The moon completely covers the sun's disc.
		case total
	}

	/// What an observer at one particular place will actually see of one eclipse.
	///
	/// Every time here is clamped to the period during which the sun is above the
	/// observer's horizon, so an eclipse that begins before sunrise reports the moment it
	/// becomes visible rather than the moment it began somewhere below the horizon.
	struct LocalCircumstances: Hashable, Sendable, Identifiable {
		/// What the eclipse looks like *from this location* at its maximum. An eclipse
		/// that is total along its central path is still `.partial` for someone standing
		/// outside that path.
		let kind: Kind

		/// Fraction of the sun's *area* hidden at maximum, 0...1.
		///
		/// This is the number the UI shows and the notification threshold tests. It is
		/// deliberately not magnitude: 90% magnitude is only about 83% obscuration, and
		/// obscuration is the one that matches both how much light is lost and what
		/// people mean by "how much of the sun is covered".
		let obscuration: Double

		/// Fraction of the sun's *diameter* covered at maximum. Quoted by most almanacs,
		/// and greater than 1 inside a total eclipse's path.
		let magnitude: Double

		/// When the moon's disc first touches the sun's, or when the eclipse first
		/// becomes visible above the horizon — whichever is later.
		let firstContact: Date

		/// The instant of greatest obscuration as seen from this location.
		let maximum: Date

		/// When the discs last touch, or when the sun sets — whichever is earlier.
		let lastContact: Date

		/// How long totality or annularity lasts here. `nil` for a partial eclipse.
		let centralDuration: TimeInterval?

		/// The sun's altitude in degrees at maximum. A single-digit altitude means the
		/// user needs a clear horizon in the right direction to see anything.
		let sunAltitudeAtMaximum: Double

		var id: Date { maximum }

		/// Whether the observer is inside the path of totality or annularity.
		var isCentral: Bool { centralDuration != nil }
	}

	// MARK: - Public API

	/// The next solar eclipse visible from `coordinate`, or `nil` if none qualifies.
	///
	/// - Parameters:
	///   - coordinate: Where the observer is standing.
	///   - date: Search forward from this instant.
	///   - within: How far ahead to look.
	///   - minimumObscuration: Ignore eclipses covering less than this fraction of the
	///     sun's area. The detail view passes 0.1; notifications pass 0.9.
	static func nextEclipse(
		at coordinate: CLLocationCoordinate2D,
		after date: Date,
		within: TimeInterval,
		minimumObscuration: Double
	) -> LocalCircumstances? {
		eclipses(
			at: coordinate,
			from: date,
			through: date.addingTimeInterval(within),
			minimumObscuration: minimumObscuration
		).first
	}

	/// Every solar eclipse visible from `coordinate` between two dates, in time order.
	static func eclipses(
		at coordinate: CLLocationCoordinate2D,
		from startDate: Date,
		through endDate: Date,
		minimumObscuration: Double
	) -> [LocalCircumstances] {
		guard endDate > startDate else { return [] }

		let startJD = Ephemeris.julianDay(from: startDate)
		let endJD = Ephemeris.julianDay(from: endDate)

		// Solar eclipses only happen at new moon, so step lunation by lunation rather
		// than scanning the whole window. `k` is Meeus's new moon index, zero at the new
		// moon of 2000 January 6.
		let firstK = Int(floor(Ephemeris.lunationIndex(julianDay: startJD))) - 1
		let lastK = Int(ceil(Ephemeris.lunationIndex(julianDay: endJD))) + 1

		var results: [LocalCircumstances] = []

		for k in firstK ... lastK {
			guard let circumstances = eclipse(lunation: k, at: coordinate) else { continue }
			guard circumstances.maximum >= startDate, circumstances.maximum <= endDate else { continue }
			guard circumstances.obscuration >= minimumObscuration else { continue }
			results.append(circumstances)
		}

		return results.sorted { $0.maximum < $1.maximum }
	}

	// MARK: - Per-lunation search

	/// Half-width of the coarse search around mean new moon, in days. True new moon can
	/// fall a little over half a day either side of the mean.
	private static let searchHalfWidth = 0.75

	/// Ecliptic latitude beyond which no eclipse is possible anywhere on Earth, padded
	/// for how far the moon's latitude can move between mean and true new moon. Screening
	/// on this costs one lunar position and rejects most lunations outright.
	private static let latitudeScreen = 2.5

	/// The sun's upper limb is still above the horizon down to about this altitude of the
	/// disc centre, once refraction is allowed for.
	private static let horizonAltitude = -0.9

	private static func eclipse(lunation k: Int, at coordinate: CLLocationCoordinate2D) -> LocalCircumstances? {
		let meanNewMoonJDE = Ephemeris.meanNewMoon(k: k)
		let meanNewMoonJD = meanNewMoonJDE - Ephemeris.deltaT(julianDay: meanNewMoonJDE) / 86400

		// Cheap rejection: if the moon passes far from the ecliptic at this new moon,
		// its shadow misses the Earth entirely and there is nothing to compute.
		let (_, moonLatitude, _) = Ephemeris.lunarPosition(jde: meanNewMoonJDE)
		guard abs(moonLatitude) < latitudeScreen else { return nil }

		// Coarse pass at 20 minute steps to find roughly when the eclipse peaks here.
		guard var best = bestSample(
			around: meanNewMoonJD,
			halfWidth: searchHalfWidth,
			step: 20.0 / 1440.0,
			at: coordinate
		) else { return nil }

		// Two refinement passes: to the minute, then to five seconds.
		if let finer = bestSample(around: best.jd, halfWidth: 25.0 / 1440.0, step: 1.0 / 1440.0, at: coordinate) {
			best = finer
		}
		if let finest = bestSample(around: best.jd, halfWidth: 90.0 / 86400.0, step: 5.0 / 86400.0, at: coordinate) {
			best = finest
		}

		let peak = best.sample
		guard peak.obscuration > 0 else { return nil }

		let kind: Kind
		if peak.separation <= peak.moonRadius - peak.sunRadius {
			kind = .total
		} else if peak.separation <= peak.sunRadius - peak.moonRadius {
			kind = .annular
		} else {
			kind = .partial
		}

		let outerRadius = { (sample: Sample) in sample.sunRadius + sample.moonRadius }
		let firstContact = contact(from: best.jd, direction: -1, at: coordinate, threshold: outerRadius)
		let lastContact = contact(from: best.jd, direction: 1, at: coordinate, threshold: outerRadius)

		var centralDuration: TimeInterval?
		if kind != .partial {
			let innerRadius = { (sample: Sample) in abs(sample.sunRadius - sample.moonRadius) }
			let secondContact = contact(from: best.jd, direction: -1, at: coordinate, threshold: innerRadius)
			let thirdContact = contact(from: best.jd, direction: 1, at: coordinate, threshold: innerRadius)
			centralDuration = (thirdContact - secondContact) * 86400
		}

		return LocalCircumstances(
			kind: kind,
			obscuration: peak.obscuration,
			magnitude: peak.magnitude,
			firstContact: Ephemeris.date(fromJulianDay: firstContact),
			maximum: Ephemeris.date(fromJulianDay: best.jd),
			lastContact: Ephemeris.date(fromJulianDay: lastContact),
			centralDuration: centralDuration,
			sunAltitudeAtMaximum: peak.sunAltitude
		)
	}

	/// Scans a window and returns the moment the two discs are closest together,
	/// considering only instants at which the sun is above the observer's horizon.
	///
	/// Ranking on separation rather than obscuration matters: obscuration saturates at
	/// 1.0 for the whole of totality, so picking the largest value would land on
	/// whichever instant happened to reach it first — the beginning of totality rather
	/// than the middle of the eclipse. Separation has a single well-defined minimum
	/// either way, and constraining the search to daylight means an eclipse interrupted
	/// by sunset reports the best the observer actually gets to see.
	private static func bestSample(
		around centreJD: Double,
		halfWidth: Double,
		step: Double,
		at coordinate: CLLocationCoordinate2D
	) -> (jd: Double, sample: Sample)? {
		var best: (jd: Double, sample: Sample)?
		let steps = Int((halfWidth * 2 / step).rounded())

		for index in 0 ... steps {
			let jd = centreJD - halfWidth + Double(index) * step
			let sample = self.sample(at: jd, coordinate: coordinate)
			guard sample.sunAltitude > horizonAltitude, sample.obscuration > 0 else { continue }
			if best == nil || sample.separation < best!.sample.separation {
				best = (jd, sample)
			}
		}

		return best
	}

	/// Walks outwards from maximum to find where the discs stop overlapping by the given
	/// measure, or where the sun reaches the horizon — whichever comes first.
	///
	/// `threshold` returns the separation at which contact occurs, so passing the sum of
	/// the radii finds first and last contact, and the absolute difference finds the
	/// start and end of totality or annularity.
	private static func contact(
		from maximumJD: Double,
		direction: Double,
		at coordinate: CLLocationCoordinate2D,
		threshold: (Sample) -> Double
	) -> Double {
		let coarseStep = 10.0 / 1440.0
		var inside = maximumJD
		var outside = maximumJD

		// Bracket the crossing. Four hours is longer than any local partial phase.
		let limit = 4.0 / 24.0
		var offset = coarseStep
		while offset <= limit {
			let jd = maximumJD + direction * offset
			let sample = self.sample(at: jd, coordinate: coordinate)
			if sample.separation >= threshold(sample) || sample.sunAltitude <= horizonAltitude {
				outside = jd
				break
			}
			inside = jd
			offset += coarseStep
		}

		guard outside != maximumJD else { return inside }

		// Bisect down to well under a second.
		for _ in 0 ..< 20 {
			let midpoint = (inside + outside) / 2
			let sample = self.sample(at: midpoint, coordinate: coordinate)
			if sample.separation >= threshold(sample) || sample.sunAltitude <= horizonAltitude {
				outside = midpoint
			} else {
				inside = midpoint
			}
		}

		return (inside + outside) / 2
	}

	// MARK: - A single instant

	/// The geometry of the two discs as seen from the observer at one instant.
	private struct Sample {
		/// Angular distance between the centres of the two discs, in degrees.
		let separation: Double
		/// The sun's apparent semidiameter in degrees.
		let sunRadius: Double
		/// The moon's apparent semidiameter in degrees.
		let moonRadius: Double
		/// The sun's altitude above the horizon in degrees.
		let sunAltitude: Double

		/// Fraction of the sun's diameter covered.
		///
		/// Once one disc sits entirely inside the other the "fraction covered" stops
		/// being meaningful, and the convention almanacs use — including NASA's
		/// published magnitudes — is the ratio of the two apparent diameters. Following
		/// that convention is what makes these numbers comparable with other sources.
		var magnitude: Double {
			guard separation < sunRadius + moonRadius else { return 0 }

			if separation <= abs(moonRadius - sunRadius) {
				return moonRadius / sunRadius
			}

			return (sunRadius + moonRadius - separation) / (2 * sunRadius)
		}

		/// Fraction of the sun's area covered — the overlap of two circles.
		var obscuration: Double {
			guard separation < sunRadius + moonRadius else { return 0 }

			if separation <= abs(moonRadius - sunRadius) {
				// One disc sits entirely inside the other: either the sun is completely
				// hidden, or the moon is small enough to leave a ring all the way round.
				return moonRadius >= sunRadius ? 1 : pow(moonRadius / sunRadius, 2)
			}

			let s = separation
			let a = sunRadius
			let b = moonRadius

			let alpha = acos(clamped((s * s + a * a - b * b) / (2 * s * a)))
			let beta = acos(clamped((s * s + b * b - a * a) / (2 * s * b)))
			let triangle = 0.5 * sqrt(max(0, (-s + a + b) * (s + a - b) * (s - a + b) * (s + a + b)))
			let overlap = a * a * alpha + b * b * beta - triangle

			return min(1, overlap / (.pi * a * a))
		}
	}

	private static func sample(at jd: Double, coordinate: CLLocationCoordinate2D) -> Sample {
		let jde = Ephemeris.julianEphemerisDay(fromJulianDay: jd)
		let t = (jde - 2451545.0) / 36525.0

		let (nutationLongitude, nutationObliquity) = Ephemeris.nutation(t: t)
		let obliquity = Ephemeris.meanObliquity(t: t) + nutationObliquity

		let (sunLongitude, sunDistanceAU) = Ephemeris.solarPosition(jde: jde)
		let apparentSunLongitude = Ephemeris.apparentSolarLongitude(
			geometricLongitude: sunLongitude,
			nutationLongitude: nutationLongitude,
			distance: sunDistanceAU
		)

		let (moonLongitude, moonLatitude, moonDistanceKm) = Ephemeris.lunarPosition(jde: jde)
		let apparentMoonLongitude = moonLongitude + nutationLongitude

		let sun = Ephemeris.equatorial(longitude: apparentSunLongitude, latitude: 0, obliquity: obliquity)
		let moon = Ephemeris.equatorial(longitude: apparentMoonLongitude, latitude: moonLatitude, obliquity: obliquity)

		// Apparent sidereal time is computed from UT, not TT — mixing the two here would
		// put the observer in the wrong place by roughly a quarter of a degree.
		let siderealTime = Ephemeris.apparentSiderealTime(
			jd: jd,
			nutationLongitude: nutationLongitude,
			obliquity: obliquity
		)
		let localSiderealTime = siderealTime + coordinate.longitude

		// The moon's horizontal parallax is nearly a degree — comparable to the whole
		// geometry of an eclipse — so the observer's offset from the centre of the Earth
		// is what makes an eclipse a local event at all.
		let observer = Ephemeris.observerVector(latitude: coordinate.latitude, localSiderealTime: localSiderealTime)

		let sunTopocentric = Ephemeris.topocentric(
			rightAscension: sun.rightAscension,
			declination: sun.declination,
			distance: sunDistanceAU * Ephemeris.astronomicalUnitKm,
			observer: observer
		)
		let moonTopocentric = Ephemeris.topocentric(
			rightAscension: moon.rightAscension,
			declination: moon.declination,
			distance: moonDistanceKm,
			observer: observer
		)

		let separation = Ephemeris.angularSeparation(
			rightAscension1: sunTopocentric.rightAscension,
			declination1: sunTopocentric.declination,
			rightAscension2: moonTopocentric.rightAscension,
			declination2: moonTopocentric.declination
		)

		let sunAltitude = Ephemeris.altitude(
			declination: sunTopocentric.declination,
			hourAngle: localSiderealTime - sunTopocentric.rightAscension,
			latitude: coordinate.latitude
		)

		// Note `umbralMoonRadiusKm`, not the mean radius: totality's duration falls out of
		// the difference between two nearly equal radii, and this is the value that makes
		// it agree with NASA's published figures.
		return Sample(
			separation: separation,
			sunRadius: degrees(asin(clamped(Ephemeris.sunRadiusKm / sunTopocentric.distance))),
			moonRadius: degrees(asin(clamped(Ephemeris.umbralMoonRadiusKm / moonTopocentric.distance))),
			sunAltitude: sunAltitude
		)
	}

	// MARK: - Shared ephemeris

	// The general-purpose astronomy lives in `Ephemeris` so the moon can be used for
	// things other than eclipses. These forward the few pure-maths helpers the eclipse
	// geometry above reads most clearly without a namespace in front of them.

	private static func radians(_ degrees: Double) -> Double { Ephemeris.radians(degrees) }
	private static func degrees(_ radians: Double) -> Double { Ephemeris.degrees(radians) }
	private static func clamped(_ value: Double) -> Double { Ephemeris.clamped(value) }
}
