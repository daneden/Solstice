//
//  SolsticeCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 20/02/2023.
//
//  Source: https://github.com/Fabiz/MeeusJs/blob/d38beae42d70f11115cca63ed2ef20ef0a92b024/lib/Astro.Solistice.js
import Foundation

struct SolsticeCalculator {
	static private let terms = [
		[485, 324.96, 1934.136],
		[203, 337.23, 32964.467],
		[199, 342.08, 20.186],
		[182, 27.85, 445267.112],
		[156, 73.14, 45036.886],
		[136, 171.52, 22518.443],
		[77, 222.54, 65928.934],
		[74, 296.72, 3034.906],
		[70, 243.58, 9037.513],
		[58, 119.81, 33718.147],
		[52, 297.17, 150.678],
		[50, 21.02, 2281.226],
		
		[45, 247.54, 29929.562],
		[44, 325.15, 31555.956],
		[29, 60.93, 4443.417],
		[18, 155.12, 67555.328],
		[17, 288.79, 4562.452],
		[16, 198.04, 62894.029],
		[14, 199.76, 31436.921],
		[12, 95.39, 14577.848],
		[12, 287.11, 31931.756],
		[12, 320.81, 34777.259],
		[9, 227.73, 1222.114],
		[8, 15.45, 16859.074]
	]
	
	static private let mc0 = [1721139.29189, 365242.13740, 0.06134, 0.00111, -0.00071],
										 jc0 = [1721233.25401, 365241.72562, -0.05232, 0.00907, 0.00025],
										 sc0 = [1721325.70455, 365242.49558, -0.11677, -0.00297, 0.00074],
										 dc0 = [1721414.39987, 365242.88257, -0.00769, -0.00933, -0.00006],
										 
										 mc2 = [2451623.80984, 365242.37404, 0.05169, -0.00411, -0.00057],
										 jc2 = [2451716.56767, 365241.62603, 0.00325, 0.00888, -0.00030],
										 sc2 = [2451810.21715, 365242.01767, -0.11575, 0.00337, 0.00078],
										 dc2 = [2451900.05952, 365242.74049, -0.06223, -0.00823, 0.00032]
	
	static private let J2000 = 2451545.0
	static private let julianCentury = 36525.0
	
	static func marchEquinox(year: Int) -> Date {
		if year < 1000 {
			return dateFromJd(jd: calculate(year, c: mc0))
		}
		
		return dateFromJd(jd: calculate(year-2000, c: mc2))
	}
	
	static func septemberEquinox(year: Int) -> Date {
		if year < 1000 {
			return dateFromJd(jd: calculate(year, c: sc0))
		}
		
		return dateFromJd(jd: calculate(year-2000, c: sc2))
	}
	
	static func juneSolstice(year: Int) -> Date {
		if year < 1000 {
			return dateFromJd(jd: calculate(year, c: jc0))
		}
		
		return dateFromJd(jd: calculate(year-2000, c: jc2))
	}
	
	static func decemberSolstice(year: Int) -> Date {
		if year < 1000 {
			return dateFromJd(jd: calculate(year, c: dc0))
		}
		
		return dateFromJd(jd: calculate(year-2000, c: dc2))
	}
	
	private static func calculate(_ year: Int, c: [Double]) -> Double {
		let J0 = horner(x: Double(year)*0.001, c: c) ?? 0
		
		let T = (J0 - J2000) / julianCentury // calc J2000 century
		
		let W = 35999.373 * .pi/180 * T - 2.47 * .pi/180
		let deltatheta = 1 + 0.0334*cos(W) + 0.0007*cos(2*W)
		var S: Double = 0
		
		var i = terms.count - 1
		while i >= 0 {
			let t = terms[i]
			S += t[0] * cos((t[1]+t[2]*T) * .pi/180)
			i -= 1
		}
		return J0 + 0.00001*S/deltatheta
	}
	
	private static func horner(x: Double, c: [Double]) -> Double? {
		var i = c.count - 1
		
		guard i >= 1 else {
			return nil
		}
		
		var y = c[i]
		while (i > 0) {
			i -= 1
			y = y*x + c[i]
		}
		return y
	}
	
	private static func dateFromJd(jd : Double) -> Date {
		let JD_JAN_1_1970_0000GMT = 2440587.5
		return  Date(timeIntervalSince1970: (jd - JD_JAN_1_1970_0000GMT) * 86400)
	}
}

extension Date {
	var recentSolstices: [Date] {
		let year = Calendar.autoupdatingCurrent.component(.year, from: self)
		let decemberSolstice = SolsticeCalculator.decemberSolstice(year: year)
		let decemberSolsticeLastYear = SolsticeCalculator.decemberSolstice(year: year - 1)
		let decemberSolsticeNextYear = SolsticeCalculator.decemberSolstice(year: year + 1)
		
		let juneSolstice = SolsticeCalculator.juneSolstice(year: year)
		let juneSolsticeLastYear = SolsticeCalculator.juneSolstice(year: year - 1)
		let juneSolsticeNextYear = SolsticeCalculator.juneSolstice(year: year + 1)
		
		return [decemberSolstice, decemberSolsticeNextYear, decemberSolsticeLastYear, juneSolstice, juneSolsticeNextYear, juneSolsticeLastYear].sorted()
	}
	
	var recentEquinoxes: [Date] {
		let year = Calendar.autoupdatingCurrent.component(.year, from: self)
		let marchEquinox = SolsticeCalculator.marchEquinox(year: year)
		let marchEquinoxLastYear = SolsticeCalculator.marchEquinox(year: year - 1)
		let marchEquinoxNextYear = SolsticeCalculator.marchEquinox(year: year + 1)
		
		let septemberEquinox = SolsticeCalculator.septemberEquinox(year: year)
		let septemberEquinoxLastYear = SolsticeCalculator.septemberEquinox(year: year - 1)
		let septemberEquinoxNextYear = SolsticeCalculator.septemberEquinox(year: year + 1)
		
		return [marchEquinox, marchEquinoxNextYear, marchEquinoxLastYear, septemberEquinox, septemberEquinoxNextYear, septemberEquinoxLastYear].sorted()
	}
	
	var previousSolstice: Date {
		let index = recentSolstices.firstIndex(where: { $0 > self })!
		return recentSolstices[index - 1]
	}
	
	var nextSolstice: Date {
		recentSolstices.first(where: { $0 > self }) ?? .now
	}
	
	var previousEquinox: Date {
		let index = recentEquinoxes.firstIndex(where: { $0 > self })!
		return recentEquinoxes[index - 1]
	}
	
	var nextEquinox: Date {
		recentEquinoxes.first(where: { $0 > self }) ?? .now
	}
}
