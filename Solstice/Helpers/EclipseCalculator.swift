//
//  EclipseCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 11/08/2026.
//
//  Local circumstances for solar eclipses.
//
//  Source: Jean Meeus, *Astronomical Algorithms* (2nd edition, Willmann-Bell 1998) —
//  chapter 22 (nutation and obliquity), chapter 25 (solar position), chapter 47 (lunar
//  position, the truncated ELP-2000/82 series) and chapter 49 (phases of the moon).
//  The ΔT model is the Espenak & Meeus polynomial set published with NASA's Five
//  Millennium Canon of Solar Eclipses.
//
//  `NTSolar` deliberately isn't reused here. Its solar model is low order — it uses a
//  linear obliquity and explicitly neglects aberration — which costs about an arcminute.
//  Against the sun's ~16 arcminute semidiameter that is roughly 6% of eclipse magnitude,
//  far too coarse to say "87% of the sun will be covered". Its internals are `private`
//  to that file in any case, and it is vendored source that shouldn't be edited.
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

		let startJD = julianDay(from: startDate)
		let endJD = julianDay(from: endDate)

		// Solar eclipses only happen at new moon, so step lunation by lunation rather
		// than scanning the whole window. `k` is Meeus's new moon index, zero at the new
		// moon of 2000 January 6.
		let firstK = Int(floor((decimalYear(julianDay: startJD) - 2000) * 12.3685)) - 1
		let lastK = Int(ceil((decimalYear(julianDay: endJD) - 2000) * 12.3685)) + 1

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
		let meanNewMoonJDE = meanNewMoon(k: k)
		let meanNewMoonJD = meanNewMoonJDE - deltaT(julianDay: meanNewMoonJDE) / 86400

		// Cheap rejection: if the moon passes far from the ecliptic at this new moon,
		// its shadow misses the Earth entirely and there is nothing to compute.
		let (_, moonLatitude, _) = lunarPosition(jde: meanNewMoonJDE)
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
			firstContact: date(fromJulianDay: firstContact),
			maximum: date(fromJulianDay: best.jd),
			lastContact: date(fromJulianDay: lastContact),
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

	/// Radius of the sun in kilometres. Chosen so the apparent semidiameter matches the
	/// conventional 959.63 arcseconds at one astronomical unit.
	private static let sunRadiusKm = 696_000.0

	/// Radius of the moon in kilometres: the value `k = 0.272281` that NASA adopts for
	/// umbral contacts, times the Earth's equatorial radius.
	///
	/// This is deliberately the umbral `k` rather than the slightly larger mean lunar
	/// radius. The moon's limb is mountainous, and eclipse prediction has long adopted
	/// the smaller figure so that computed durations of totality match what observers
	/// actually time. Using it reproduces NASA's published eclipse magnitudes; the mean
	/// radius overstates them by about 0.2%, which sounds negligible but lands squarely
	/// on the difference of two nearly equal radii that sets how long totality lasts.
	private static let moonRadiusKm = 1736.65

	private static let earthRadiusKm = 6378.14
	private static let astronomicalUnitKm = 149_597_870.7

	private static func sample(at jd: Double, coordinate: CLLocationCoordinate2D) -> Sample {
		let jde = jd + deltaT(julianDay: jd) / 86400
		let t = (jde - 2451545.0) / 36525.0

		let (nutationLongitude, nutationObliquity) = nutation(t: t)
		let obliquity = meanObliquity(t: t) + nutationObliquity

		let (sunLongitude, sunDistanceAU) = solarPosition(jde: jde)
		let apparentSunLongitude = sunLongitude + nutationLongitude - 20.4898 / 3600 / sunDistanceAU

		let (moonLongitude, moonLatitude, moonDistanceKm) = lunarPosition(jde: jde)
		let apparentMoonLongitude = moonLongitude + nutationLongitude

		let sun = equatorial(longitude: apparentSunLongitude, latitude: 0, obliquity: obliquity)
		let moon = equatorial(longitude: apparentMoonLongitude, latitude: moonLatitude, obliquity: obliquity)

		// Apparent sidereal time is computed from UT, not TT — mixing the two here would
		// put the observer in the wrong place by roughly a quarter of a degree.
		let siderealTime = apparentSiderealTime(
			jd: jd,
			nutationLongitude: nutationLongitude,
			obliquity: obliquity
		)
		let localSiderealTime = siderealTime + coordinate.longitude

		// The moon's horizontal parallax is nearly a degree — comparable to the whole
		// geometry of an eclipse — so the observer's offset from the centre of the Earth
		// is what makes an eclipse a local event at all.
		let observer = observerVector(latitude: coordinate.latitude, localSiderealTime: localSiderealTime)

		let sunTopocentric = topocentric(
			rightAscension: sun.rightAscension,
			declination: sun.declination,
			distance: sunDistanceAU * astronomicalUnitKm,
			observer: observer
		)
		let moonTopocentric = topocentric(
			rightAscension: moon.rightAscension,
			declination: moon.declination,
			distance: moonDistanceKm,
			observer: observer
		)

		let separation = angularSeparation(
			rightAscension1: sunTopocentric.rightAscension,
			declination1: sunTopocentric.declination,
			rightAscension2: moonTopocentric.rightAscension,
			declination2: moonTopocentric.declination
		)

		let hourAngle = localSiderealTime - sunTopocentric.rightAscension
		let sunAltitude = degrees(asin(clamped(
			sin(radians(coordinate.latitude)) * sin(radians(sunTopocentric.declination))
				+ cos(radians(coordinate.latitude)) * cos(radians(sunTopocentric.declination))
				* cos(radians(hourAngle))
		)))

		return Sample(
			separation: separation,
			sunRadius: degrees(asin(clamped(sunRadiusKm / sunTopocentric.distance))),
			moonRadius: degrees(asin(clamped(moonRadiusKm / moonTopocentric.distance))),
			sunAltitude: sunAltitude
		)
	}

	// MARK: - Coordinate machinery

	private struct EquatorialPosition {
		let rightAscension: Double
		let declination: Double
		let distance: Double
	}

	private static func equatorial(
		longitude: Double,
		latitude: Double,
		obliquity: Double
	) -> (rightAscension: Double, declination: Double) {
		let l = radians(longitude)
		let b = radians(latitude)
		let e = radians(obliquity)

		let rightAscension = atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))
		let declination = asin(clamped(sin(b) * cos(e) + cos(b) * sin(e) * sin(l)))

		return (normalise(degrees(rightAscension)), degrees(declination))
	}

	/// The observer's position relative to the centre of the Earth, in kilometres, in the
	/// same equatorial frame the bodies are expressed in.
	private static func observerVector(latitude: Double, localSiderealTime: Double) -> (x: Double, y: Double, z: Double) {
		// The Earth is flattened, so geodetic latitude has to be converted before it can
		// be used as a direction from the centre.
		let clampedLatitude = min(max(latitude, -89.9999), 89.9999)
		let phi = radians(clampedLatitude)
		let u = atan(0.99664719 * tan(phi))
		let rhoSinPhi = 0.99664719 * sin(u)
		let rhoCosPhi = cos(u)
		let theta = radians(localSiderealTime)

		return (
			x: earthRadiusKm * rhoCosPhi * cos(theta),
			y: earthRadiusKm * rhoCosPhi * sin(theta),
			z: earthRadiusKm * rhoSinPhi
		)
	}

	private static func topocentric(
		rightAscension: Double,
		declination: Double,
		distance: Double,
		observer: (x: Double, y: Double, z: Double)
	) -> EquatorialPosition {
		let ra = radians(rightAscension)
		let dec = radians(declination)

		let x = distance * cos(dec) * cos(ra) - observer.x
		let y = distance * cos(dec) * sin(ra) - observer.y
		let z = distance * sin(dec) - observer.z

		let range = sqrt(x * x + y * y + z * z)

		return EquatorialPosition(
			rightAscension: normalise(degrees(atan2(y, x))),
			declination: degrees(asin(clamped(z / range))),
			distance: range
		)
	}

	/// Great-circle distance in degrees, using the form that stays accurate for the very
	/// small separations an eclipse involves.
	private static func angularSeparation(
		rightAscension1: Double,
		declination1: Double,
		rightAscension2: Double,
		declination2: Double
	) -> Double {
		let d1 = radians(declination1)
		let d2 = radians(declination2)
		let deltaRA = radians(rightAscension2 - rightAscension1)

		let numerator = sqrt(
			pow(cos(d2) * sin(deltaRA), 2)
				+ pow(cos(d1) * sin(d2) - sin(d1) * cos(d2) * cos(deltaRA), 2)
		)
		let denominator = sin(d1) * sin(d2) + cos(d1) * cos(d2) * cos(deltaRA)

		return degrees(atan2(numerator, denominator))
	}

	private static func apparentSiderealTime(
		jd: Double,
		nutationLongitude: Double,
		obliquity: Double
	) -> Double {
		let t = (jd - 2451545.0) / 36525.0
		let mean = 280.46061837
			+ 360.98564736629 * (jd - 2451545.0)
			+ 0.000387933 * t * t
			- t * t * t / 38_710_000.0

		return normalise(mean + nutationLongitude * cos(radians(obliquity)))
	}

	// MARK: - Solar position (Meeus chapter 25)

	/// Geometric longitude in degrees and radius vector in astronomical units.
	private static func solarPosition(jde: Double) -> (longitude: Double, distance: Double) {
		let t = (jde - 2451545.0) / 36525.0

		let meanLongitude = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
		let meanAnomaly = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
		let eccentricity = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t

		let m = radians(meanAnomaly)
		let centre = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(m)
			+ (0.019993 - 0.000101 * t) * sin(2 * m)
			+ 0.000289 * sin(3 * m)

		let trueLongitude = meanLongitude + centre
		let trueAnomaly = radians(meanAnomaly + centre)
		let distance = 1.000001018 * (1 - eccentricity * eccentricity) / (1 + eccentricity * cos(trueAnomaly))

		return (normalise(trueLongitude), distance)
	}

	// MARK: - Lunar position (Meeus chapter 47)

	/// Apparent geocentric ecliptic longitude and latitude in degrees, and distance in
	/// kilometres. Accurate to roughly 10 arcseconds in longitude and 4 in latitude,
	/// which is a small fraction of a percent of eclipse obscuration.
	private static func lunarPosition(jde: Double) -> (longitude: Double, latitude: Double, distance: Double) {
		let t = (jde - 2451545.0) / 36525.0
		let t2 = t * t
		let t3 = t2 * t
		let t4 = t3 * t

		let meanLongitude = 218.3164477 + 481_267.88123421 * t - 0.0015786 * t2 + t3 / 538_841 - t4 / 65_194_000
		let elongation = 297.8501921 + 445_267.1114034 * t - 0.0018819 * t2 + t3 / 545_868 - t4 / 113_065_000
		let solarAnomaly = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24_490_000
		let lunarAnomaly = 134.9633964 + 477_198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14_712_000
		let argumentOfLatitude = 93.2720950 + 483_202.0175233 * t - 0.0036539 * t2 - t3 / 3_526_000 + t4 / 863_310_000

		let a1 = 119.75 + 131.849 * t
		let a2 = 53.09 + 479_264.290 * t
		let a3 = 313.45 + 481_266.484 * t

		// The sun's varying eccentricity damps terms involving its anomaly.
		let e = 1 - 0.002516 * t - 0.0000074 * t2

		var sumLongitude = 0.0
		var sumDistance = 0.0

		for term in lunarTermsA {
			let argument = radians(
				term[0] * elongation + term[1] * solarAnomaly
					+ term[2] * lunarAnomaly + term[3] * argumentOfLatitude
			)
			let damping = pow(e, abs(term[1]))
			sumLongitude += term[4] * damping * sin(argument)
			sumDistance += term[5] * damping * cos(argument)
		}

		var sumLatitude = 0.0

		for term in lunarTermsB {
			let argument = radians(
				term[0] * elongation + term[1] * solarAnomaly
					+ term[2] * lunarAnomaly + term[3] * argumentOfLatitude
			)
			sumLatitude += term[4] * pow(e, abs(term[1])) * sin(argument)
		}

		// Additive terms for Venus, Jupiter and the flattening of the Earth.
		sumLongitude += 3958 * sin(radians(a1))
			+ 1962 * sin(radians(meanLongitude - argumentOfLatitude))
			+ 318 * sin(radians(a2))

		sumLatitude += -2235 * sin(radians(meanLongitude))
			+ 382 * sin(radians(a3))
			+ 175 * sin(radians(a1 - argumentOfLatitude))
			+ 175 * sin(radians(a1 + argumentOfLatitude))
			+ 127 * sin(radians(meanLongitude - lunarAnomaly))
			- 115 * sin(radians(meanLongitude + lunarAnomaly))

		return (
			longitude: normalise(meanLongitude + sumLongitude / 1_000_000),
			latitude: sumLatitude / 1_000_000,
			distance: 385_000.56 + sumDistance / 1000
		)
	}

	// MARK: - Nutation and obliquity (Meeus chapter 22)

	private static func nutation(t: Double) -> (longitude: Double, obliquity: Double) {
		let omega = radians(125.04452 - 1934.136261 * t)
		let solarLongitude = radians(280.4665 + 36000.7698 * t)
		let lunarLongitude = radians(218.3165 + 481_267.8813 * t)

		let longitude = (-17.20 * sin(omega)
			- 1.32 * sin(2 * solarLongitude)
			- 0.23 * sin(2 * lunarLongitude)
			+ 0.21 * sin(2 * omega)) / 3600

		let obliquity = (9.20 * cos(omega)
			+ 0.57 * cos(2 * solarLongitude)
			+ 0.10 * cos(2 * lunarLongitude)
			- 0.09 * cos(2 * omega)) / 3600

		return (longitude, obliquity)
	}

	private static func meanObliquity(t: Double) -> Double {
		23.0 + 26.0 / 60.0 + 21.448 / 3600.0
			- (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0
	}

	// MARK: - New moon (Meeus chapter 49)

	/// Mean new moon for lunation `k`, as a Julian Ephemeris Day. Only used as a starting
	/// point — the true new moon can be over half a day either side, which the search
	/// window around it absorbs.
	private static func meanNewMoon(k: Int) -> Double {
		let k = Double(k)
		let t = k / 1236.85

		return 2_451_550.09766
			+ 29.530588861 * k
			+ 0.00015437 * t * t
			- 0.000000150 * t * t * t
			+ 0.00000000073 * t * t * t * t
	}

	// MARK: - ΔT

	/// The difference between Terrestrial Time and Universal Time in seconds.
	///
	/// Positions are computed in TT while the observer's rotation is tracked in UT;
	/// getting this wrong simply shifts every predicted contact time by the same amount.
	/// Polynomials from Espenak & Meeus.
	private static func deltaT(julianDay: Double) -> Double {
		let year = decimalYear(julianDay: julianDay)

		switch year {
		case ..<1920:
			let t = year - 1900
			return -2.79 + 1.494119 * t - 0.0598939 * t * t + 0.0061966 * t * t * t - 0.000197 * pow(t, 4)
		case ..<1941:
			let t = year - 1920
			return 21.20 + 0.84493 * t - 0.076100 * t * t + 0.0020936 * t * t * t
		case ..<1961:
			let t = year - 1950
			return 29.07 + 0.407 * t - t * t / 233 + t * t * t / 2547
		case ..<1986:
			let t = year - 1975
			return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718
		case ..<2005:
			let t = year - 2000
			return 63.86 + 0.3345 * t - 0.060374 * t * t + 0.0017275 * t * t * t
				+ 0.000651814 * pow(t, 4) + 0.00002373599 * pow(t, 5)
		case ..<2050:
			let t = year - 2000
			return 62.92 + 0.32217 * t + 0.005589 * t * t
		case ..<2150:
			return -20 + 32 * pow((year - 1820) / 100, 2) - 0.5628 * (2150 - year)
		default:
			let u = (year - 1820) / 100
			return -20 + 32 * u * u
		}
	}

	// MARK: - Julian day helpers

	private static let julianDayAtUnixEpoch = 2_440_587.5

	private static func julianDay(from date: Date) -> Double {
		date.timeIntervalSince1970 / 86400 + julianDayAtUnixEpoch
	}

	private static func date(fromJulianDay julianDay: Double) -> Date {
		Date(timeIntervalSince1970: (julianDay - julianDayAtUnixEpoch) * 86400)
	}

	/// Year with a fractional part, derived arithmetically rather than through `Calendar`.
	///
	/// The ΔT polynomials are defined over proleptic Gregorian years, and reading a year
	/// back through the user's calendar would give the wrong answer in a non-Gregorian
	/// region — the same hazard `SolsticeCalculator` documents.
	private static func decimalYear(julianDay: Double) -> Double {
		let z = (julianDay + 0.5).rounded(.down)

		var a = z
		if z >= 2_299_161 {
			let alpha = ((z - 1_867_216.25) / 36524.25).rounded(.down)
			a = z + 1 + alpha - (alpha / 4).rounded(.down)
		}

		let b = a + 1524
		let c = ((b - 122.1) / 365.25).rounded(.down)
		let d = (365.25 * c).rounded(.down)
		let e = ((b - d) / 30.6001).rounded(.down)

		let month = e < 14 ? e - 1 : e - 13
		let year = month > 2 ? c - 4716 : c - 4715

		return year + (month - 0.5) / 12
	}

	// MARK: - Small helpers

	private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
	private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

	private static func normalise(_ degrees: Double) -> Double {
		let wrapped = degrees.truncatingRemainder(dividingBy: 360)
		return wrapped < 0 ? wrapped + 360 : wrapped
	}

	/// Guards the inverse trigonometric functions against arguments that drift a hair
	/// outside their domain through rounding.
	private static func clamped(_ value: Double) -> Double {
		min(max(value, -1), 1)
	}

	// MARK: - Periodic terms

	/// Meeus table 47.A — columns are the multiples of D, M, M′ and F, then the
	/// coefficients for longitude (units of 1e-6 degrees) and distance (units of metres).
	private static let lunarTermsA: [[Double]] = [
		[0, 0, 1, 0, 6_288_774, -20_905_355],
		[2, 0, -1, 0, 1_274_027, -3_699_111],
		[2, 0, 0, 0, 658_314, -2_955_968],
		[0, 0, 2, 0, 213_618, -569_925],
		[0, 1, 0, 0, -185_116, 48888],
		[0, 0, 0, 2, -114_332, -3149],
		[2, 0, -2, 0, 58793, 246_158],
		[2, -1, -1, 0, 57066, -152_138],
		[2, 0, 1, 0, 53322, -170_733],
		[2, -1, 0, 0, 45758, -204_586],
		[0, 1, -1, 0, -40923, -129_620],
		[1, 0, 0, 0, -34720, 108_743],
		[0, 1, 1, 0, -30383, 104_755],
		[2, 0, 0, -2, 15327, 10321],
		[0, 0, 1, 2, -12528, 0],
		[0, 0, 1, -2, 10980, 79661],
		[4, 0, -1, 0, 10675, -34782],
		[0, 0, 3, 0, 10034, -23210],
		[4, 0, -2, 0, 8548, -21636],
		[2, 1, -1, 0, -7888, 24208],
		[2, 1, 0, 0, -6766, 30824],
		[1, 0, -1, 0, -5163, -8379],
		[1, 1, 0, 0, 4987, -16675],
		[2, -1, 1, 0, 4036, -12831],
		[2, 0, 2, 0, 3994, -10445],
		[4, 0, 0, 0, 3861, -11650],
		[2, 0, -3, 0, 3665, 14403],
		[0, 1, -2, 0, -2689, -7003],
		[2, 0, -1, 2, -2602, 0],
		[2, -1, -2, 0, 2390, 10056],
		[1, 0, 1, 0, -2348, 6322],
		[2, -2, 0, 0, 2236, -9884],
		[0, 1, 2, 0, -2120, 5751],
		[0, 2, 0, 0, -2069, 0],
		[2, -2, -1, 0, 2048, -4950],
		[2, 0, 1, -2, -1773, 4130],
		[2, 0, 0, 2, -1595, 0],
		[4, -1, -1, 0, 1215, -3958],
		[0, 0, 2, 2, -1110, 0],
		[3, 0, -1, 0, -892, 3258],
		[2, 1, 1, 0, -810, 2616],
		[4, -1, -2, 0, 759, -1897],
		[0, 2, -1, 0, -713, -2117],
		[2, 2, -1, 0, -700, 2354],
		[2, 1, -2, 0, 691, 0],
		[2, -1, 0, -2, 596, 0],
		[4, 0, 1, 0, 549, -1423],
		[0, 0, 4, 0, 537, -1117],
		[4, -1, 0, 0, 520, -1571],
		[1, 0, -2, 0, -487, -1739],
		[2, 1, 0, -2, -399, 0],
		[0, 0, 2, -2, -381, -4421],
		[1, 1, 1, 0, 351, 0],
		[3, 0, -2, 0, -340, 0],
		[4, 0, -3, 0, 330, 0],
		[2, -1, 2, 0, 327, 0],
		[0, 2, 1, 0, -323, 1165],
		[1, 1, -1, 0, 299, 0],
		[2, 0, 3, 0, 294, 0],
		[2, 0, -1, -2, 0, 8752],
	]

	/// Meeus table 47.B — columns are the multiples of D, M, M′ and F, then the
	/// coefficient for latitude (units of 1e-6 degrees).
	private static let lunarTermsB: [[Double]] = [
		[0, 0, 0, 1, 5_128_122],
		[0, 0, 1, 1, 280_602],
		[0, 0, 1, -1, 277_693],
		[2, 0, 0, -1, 173_237],
		[2, 0, -1, 1, 55413],
		[2, 0, -1, -1, 46271],
		[2, 0, 0, 1, 32573],
		[0, 0, 2, 1, 17198],
		[2, 0, 1, -1, 9266],
		[0, 0, 2, -1, 8822],
		[2, -1, 0, -1, 8216],
		[2, 0, -2, -1, 4324],
		[2, 0, 1, 1, 4200],
		[2, 1, 0, -1, -3359],
		[2, -1, -1, 1, 2463],
		[2, -1, 0, 1, 2211],
		[2, -1, -1, -1, 2065],
		[0, 1, -1, -1, -1870],
		[4, 0, -1, -1, 1828],
		[0, 1, 0, 1, -1794],
		[0, 0, 0, 3, -1749],
		[0, 1, -1, 1, -1565],
		[1, 0, 0, 1, -1491],
		[0, 1, 1, 1, -1475],
		[0, 1, 1, -1, -1410],
		[0, 1, 0, -1, -1344],
		[1, 0, 0, -1, -1335],
		[0, 0, 3, 1, 1107],
		[4, 0, 0, -1, 1021],
		[4, 0, -1, 1, 833],
		[0, 0, 1, -3, 777],
		[4, 0, -2, 1, 671],
		[2, 0, 0, -3, 607],
		[2, 0, 2, -1, 596],
		[2, -1, 1, -1, 491],
		[2, 0, -2, 1, -451],
		[0, 0, 3, -1, 439],
		[2, 0, 2, 1, 422],
		[2, 0, -3, -1, 421],
		[2, 1, -1, 1, -366],
		[2, 1, 0, 1, -351],
		[4, 0, 0, 1, 331],
		[2, -1, 1, 1, 315],
		[2, -2, 0, -1, 302],
		[0, 0, 1, 3, -283],
		[2, 1, 1, -1, -229],
		[1, 1, 0, -1, 223],
		[1, 1, 0, 1, 223],
		[0, 1, -2, -1, -220],
		[2, 1, -1, -1, -220],
		[1, 0, 1, 1, -185],
		[2, -1, -2, -1, 181],
		[0, 1, 2, 1, -177],
		[4, 0, -2, -1, 176],
		[4, -1, -1, -1, 166],
		[1, 0, 1, -1, -164],
		[4, 0, 1, -1, 132],
		[1, 0, -1, -1, -119],
		[4, -1, 0, -1, 115],
		[2, -2, 0, 1, 107],
	]
}
