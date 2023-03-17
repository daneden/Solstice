//
//  SkyGradient.swift
//  Solstice
//
//  Created by Daniel Eden on 21/02/2023.
//

import Foundation
import SwiftUI
import Solar

struct SkyGradient {
	static let dawn = [
		Color(red: 0.388, green: 0.435, blue: 0.643),
		Color(red: 0.91, green: 0.796, blue: 0.753)
	]
	
	static let morning = [
		Color(red: 0.11, green: 0.573, blue: 0.824),
		Color(red: 0.749, green: 0.788, blue: 0.896)
	]
	
	static let noon = [
		Color(red: 0.184, green: 0.6, blue: 0.9),
		Color(red: 0.4, green: 0.8, blue: 0.93)
	]
	
	static let afternoon = [
		Color(red: 0, green: 0.353, blue: 0.655),
		Color(red: 1, green: 0.942, blue: 0.854)
	]
	
	static let evening = [
		Color(red: 0.15, green: 0.261, blue: 0.49),
		Color(red: 0.424, green: 0.357, blue: 0.482),
		Color(red: 0.753, green: 0.424, blue: 0.518)
	]
	
	static let night = [
		Color(red: 0.007, green: 0.03, blue: 0.17),
		Color(red: 0.234, green: 0.446, blue: 0.58)
	]
	
	static var colors: [[Color]] {
		[dawn, morning, noon, afternoon, evening, night]
	}
	
	static func getCurrentPalette(for time: Date = .now) -> [Color] {
		let timeAsIndex = Int(Double(calendar.component(.hour, from: time) + 8) / 6) % colors.count
		return colors[timeAsIndex]
	}
	
	static func getCurrentPalette(for daylight: Solar) -> [Color] {
		let sunrise = daylight.safeSunrise.addingTimeInterval(-60 * 30)
		let sunset = daylight.safeSunset.addingTimeInterval(60 * 30)
		
		let colorsExcludingNight = Array(colors.dropLast(1))
		
		if daylight.date < sunrise || daylight.date > sunset {
			return night
		} else {
			let index = floor((sunrise.distance(to: daylight.date) / daylight.daylightDuration) * Double(colorsExcludingNight.count - 1))
			
			return colorsExcludingNight[Int(index)]
		}
	}
}

struct SkyGradient_Previews: PreviewProvider {
	static var previews: some View {
		HStack(spacing: 0) {
			ForEach(SkyGradient.colors, id: \.self) { gradientStops in
				LinearGradient(colors: gradientStops, startPoint: .top, endPoint: .bottom)
			}
		}
	}
}
