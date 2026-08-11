//
//  Ephemeris.swift
//  Solstice
//
//  Created by Daniel Eden on 11/08/2026.
//
//  Positions of the sun and moon, and the coordinate machinery for converting them into
//  what an observer at a particular place would actually see.
//
//  Source: Jean Meeus, *Astronomical Algorithms* (2nd edition, Willmann-Bell 1998) —
//  chapter 12 (sidereal time), chapter 13 (coordinate transformation), chapter 22
//  (nutation and obliquity), chapter 25 (solar position), chapter 40 (parallax),
//  chapter 47 (lunar position, the truncated ELP-2000/82 series) and chapter 49 (phases
//  of the moon). The ΔT model is the Espenak & Meeus polynomial set published with
//  NASA's Five Millennium Canon of Solar Eclipses.
//
//  This started life inside `EclipseCalculator` and was lifted out unchanged so the moon
//  could be used for something other than eclipses. Accuracy is Meeus's: roughly 10
//  arcseconds in lunar longitude and 4 in latitude, which is a fraction of a percent of
//  the apparent size of either body.
//
//  `NTSolar` is not used for any of this. Its solar model is low order — linear obliquity,
//  aberration explicitly neglected — which costs about an arcminute, and its internals are
//  private to that file in any case.
//

import Foundation

enum Ephemeris {
	// MARK: - Constants

	/// Radius of the sun in kilometres. Chosen so the apparent semidiameter matches the
	/// conventional 959.63 arcseconds at one astronomical unit.
	static let sunRadiusKm = 696_000.0

	/// Radius of the moon in kilometres, from the IAU `k = 0.2725076` times the Earth's
	/// equatorial radius. The right figure for how large the moon *looks*.
	static let moonRadiusKm = 1738.09

	/// Radius of the moon in kilometres from the smaller `k = 0.272281` that NASA adopts
	/// for umbral contacts.
	///
	/// Only eclipse totality should use this. The moon's limb is mountainous, and eclipse
	/// prediction has long adopted the smaller figure so computed durations of totality
	/// match what observers actually time — it reproduces NASA's published eclipse
	/// magnitudes, where `moonRadiusKm` overstates them by about 0.2%. That sounds
	/// negligible until it lands on the difference between two nearly equal radii, which
	/// is exactly what sets how long totality lasts. For anything else — the moon's
	/// apparent size, moonrise, illumination — it is simply the wrong number.
	static let umbralMoonRadiusKm = 1736.65

	static let earthRadiusKm = 6378.14
	static let astronomicalUnitKm = 149_597_870.7

	// MARK: - Julian day

	private static let julianDayAtUnixEpoch = 2_440_587.5

	static func julianDay(from date: Date) -> Double {
		date.timeIntervalSince1970 / 86400 + julianDayAtUnixEpoch
	}

	static func date(fromJulianDay julianDay: Double) -> Date {
		Date(timeIntervalSince1970: (julianDay - julianDayAtUnixEpoch) * 86400)
	}

	/// Year with a fractional part, derived arithmetically rather than through `Calendar`.
	///
	/// The ΔT polynomials are defined over proleptic Gregorian years, and reading a year
	/// back through the user's calendar would give the wrong answer in a non-Gregorian
	/// region — the same hazard `SolsticeCalculator` documents.
	static func decimalYear(julianDay: Double) -> Double {
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

	// MARK: - ΔT

	/// The difference between Terrestrial Time and Universal Time in seconds.
	///
	/// Positions are computed in TT while the observer's rotation is tracked in UT;
	/// getting this wrong simply shifts every predicted time by the same amount.
	/// Polynomials from Espenak & Meeus.
	static func deltaT(julianDay: Double) -> Double {
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

	/// Julian Ephemeris Day (Terrestrial Time) for a Julian Day in Universal Time.
	static func julianEphemerisDay(fromJulianDay jd: Double) -> Double {
		jd + deltaT(julianDay: jd) / 86400
	}

	// MARK: - Nutation and obliquity (Meeus chapter 22)

	static func nutation(t: Double) -> (longitude: Double, obliquity: Double) {
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

	static func meanObliquity(t: Double) -> Double {
		23.0 + 26.0 / 60.0 + 21.448 / 3600.0
			- (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0
	}

	// MARK: - Solar position (Meeus chapter 25)

	/// Geometric longitude in degrees and radius vector in astronomical units.
	static func solarPosition(jde: Double) -> (longitude: Double, distance: Double) {
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

	/// Apparent solar longitude in degrees — geometric longitude with nutation and the
	/// aberration of light applied.
	///
	/// Takes the already-computed geometric position rather than recomputing it, since
	/// callers invoke this inside tight sampling loops.
	static func apparentSolarLongitude(
		geometricLongitude: Double,
		nutationLongitude: Double,
		distance: Double
	) -> Double {
		geometricLongitude + nutationLongitude - 20.4898 / 3600 / distance
	}

	// MARK: - Lunar position (Meeus chapter 47)

	/// Apparent geocentric ecliptic longitude and latitude in degrees, and distance in
	/// kilometres. Accurate to roughly 10 arcseconds in longitude and 4 in latitude.
	static func lunarPosition(jde: Double) -> (longitude: Double, latitude: Double, distance: Double) {
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

	/// The moon's equatorial horizontal parallax in degrees — how far its apparent
	/// position shifts between the centre of the Earth and a point on its surface. Nearly
	/// a degree, which is why anything lunar has to be computed topocentrically.
	static func lunarHorizontalParallax(distance: Double) -> Double {
		degrees(asin(clamped(earthRadiusKm / distance)))
	}

	// MARK: - Phases of the moon (Meeus chapter 49)

	/// Mean new moon for lunation `k`, as a Julian Ephemeris Day. A starting point only —
	/// the true new moon can be over half a day either side.
	static func meanNewMoon(k: Int) -> Double {
		let k = Double(k)
		let t = k / 1236.85

		return 2_451_550.09766
			+ 29.530588861 * k
			+ 0.00015437 * t * t
			- 0.000000150 * t * t * t
			+ 0.00000000073 * t * t * t * t
	}

	/// Meeus's lunation index for a moment, zero at the new moon of 2000 January 6.
	static func lunationIndex(julianDay: Double) -> Double {
		(decimalYear(julianDay: julianDay) - 2000) * 12.3685
	}

	/// The mean length of a lunation in days.
	static let synodicMonth = 29.530588861

	// MARK: - Coordinate machinery

	struct EquatorialPosition {
		let rightAscension: Double
		let declination: Double
		let distance: Double
	}

	static func equatorial(
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
	static func observerVector(latitude: Double, localSiderealTime: Double) -> (x: Double, y: Double, z: Double) {
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

	static func topocentric(
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

	/// Great-circle distance in degrees, using the form that stays accurate for very
	/// small separations.
	static func angularSeparation(
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

	static func apparentSiderealTime(
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

	/// Altitude above the horizon in degrees for a body already in topocentric
	/// coordinates.
	static func altitude(
		declination: Double,
		hourAngle: Double,
		latitude: Double
	) -> Double {
		degrees(asin(clamped(
			sin(radians(latitude)) * sin(radians(declination))
				+ cos(radians(latitude)) * cos(radians(declination)) * cos(radians(hourAngle))
		)))
	}

	// MARK: - Small helpers

	static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
	static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

	static func normalise(_ degrees: Double) -> Double {
		let wrapped = degrees.truncatingRemainder(dividingBy: 360)
		return wrapped < 0 ? wrapped + 360 : wrapped
	}

	/// Guards the inverse trigonometric functions against arguments that drift a hair
	/// outside their domain through rounding.
	static func clamped(_ value: Double) -> Double {
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
