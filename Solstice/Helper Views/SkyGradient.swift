//
//  SkyGradient.swift
//  Solstice
//
//  Created by Daniel Eden on 21/02/2023.
//

import Foundation
import SwiftUI
import Solar
import CoreLocation

extension Solar: @unchecked Sendable {}

struct SkyGradient: View, ShapeStyle {
	var solar: Solar = Solar(coordinate: .proxiedToTimeZone)!
	
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
		[night, dawn, morning, noon, afternoon, evening, night]
	}
	
	var colors: [[Color]] {
		let daylightHours = Int((solar.daylightDuration / (60 * 60)) / 2)
		let amColors = [Self.night, Self.dawn, Self.morning]
		let pmColors = [Self.afternoon, Self.evening, Self.night]
		
		let noon = Array(repeating: Self.noon, count: daylightHours)
		
		if solar.daylightDuration <= 0 {
			return [Self.night, Self.dawn, Self.evening, Self.night]
		} else if solar.daylightDuration >= .twentyFourHours {
			return [Self.dawn, Self.morning] + noon + [Self.afternoon, Self.evening]
		}
		
		return amColors + noon + pmColors
	}
	
	var stops: [Color] {
		let sunrise = solar.safeSunrise
		let sunset = solar.safeSunset
		let twilightDuration: TimeInterval = 60 * 100
		let duration = sunrise.addingTimeInterval(-twilightDuration).distance(to: sunset.addingTimeInterval(twilightDuration))
		let progress = sunrise.distance(to: solar.date) / duration
		let progressThroughStops = progress * Double(colors.count)
		let index = min(max(0, Int(floor(progressThroughStops))), colors.count - 1)
		let nextIndex = max(0, min(colors.count - 1, Int(ceil(progressThroughStops))))
		let stopsA = colors[index]
		let stopsB = colors[nextIndex]
		let progressThroughCurrentStops = progressThroughStops - Double(index)
		
		return [
			stopsA[0].mix(with: stopsB[0], by: progressThroughCurrentStops),
			stopsA[1].mix(with: stopsB[1], by: progressThroughCurrentStops),
		]
	}
	
	var body: LinearGradient {
		LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
	}
}

fileprivate struct PreviewContainer: View {
	@State var date = Date.now
	
	var solars: [Solar] {
		var result = [Solar?]()
		
		for i in stride(from: 0, to: 180, by: 15) {
			let location = CLLocationCoordinate2D(latitude: Double(i) - 90, longitude: 0)
			result.append(Solar(for: date, coordinate: location))
		}
		
		return result.compactMap { $0 }
	}
	
	var body: some View {
		TimelineView(.animation) { t in
			VStack(spacing: 0) {
				ForEach(solars, id: \.coordinate.latitude) { solar in
					ZStack {
						SkyGradient(solar: solar)
						
						HStack {
							Text(solar.date, style: .time)
								.font(.largeTitle)
							
							Spacer()
							VStack {
								Text(solar.safeSunrise...solar.safeSunset)
								Text(solar.daylightDuration.localizedString)
							}
						}
						.padding()
					}
				}
			}
			.monospacedDigit()
			.environment(\.colorScheme, .dark)
			.task(id: t.date) {
				date = date.addingTimeInterval(60)
			}
		}
	}
}

#Preview {
	ScrollView {
		PreviewContainer()
	}
}
