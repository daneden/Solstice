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

extension Solar: @unchecked @retroactive Sendable {}

struct SkyGradient: View, ShapeStyle {
	var solar: Solar? = Solar(coordinate: .proxiedToTimeZone)
	
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
		let duration = solar?.daylightDuration ?? 43200
		let daylightHours = Int((duration / (60 * 60)) / 2)
		let amColors = [Self.night, Self.dawn, Self.morning]
		let pmColors = [Self.afternoon, Self.evening, Self.night]
		
		let noon = Array(repeating: Self.noon, count: daylightHours)
		
		if duration <= 0 {
			return [Self.night, Self.dawn, Self.evening, Self.night]
		} else if duration >= .twentyFourHours {
			return [Self.dawn, Self.morning] + noon + [Self.afternoon, Self.evening]
		}
		
		return amColors + noon + pmColors
	}
	
	var stops: [Color] {
		let sunrise: Date = solar?.safeSunrise ?? .now.startOfDay
		let sunset: Date = solar?.safeSunset ?? .now.endOfDay
		let currentDate: Date = solar?.date ?? .now
		let twilightDuration: TimeInterval = 60 * 180

		let dayStart: Date = sunrise.addingTimeInterval(-twilightDuration)
		let dayEnd: Date = sunset.addingTimeInterval(twilightDuration)
		let duration: TimeInterval = dayStart.distance(to: dayEnd)

		let progressStart: Date = sunrise.addingTimeInterval(-twilightDuration / 1.5)
		let progress: Double = progressStart.distance(to: currentDate) / duration

		let colorCount: Int = colors.count
		let progressThroughStops: Double = progress * Double(colorCount)
		let index: Int = min(max(0, Int(floor(progressThroughStops))), colorCount - 1)
		let nextIndex: Int = max(0, min(colorCount - 1, Int(ceil(progressThroughStops))))

		let stopsA: [Color] = colors[index]
		let stopsB: [Color] = colors[nextIndex]
		let progressThroughCurrentStops: Double = progressThroughStops - Double(index)

		let color0: Color = stopsA[0].mix(with: stopsB[0], by: progressThroughCurrentStops)
		let color1: Color = stopsA[1].mix(with: stopsB[1], by: progressThroughCurrentStops)

		return [color0, color1]
	}
	
	var body: LinearGradient {
		LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
	}
}

extension Solar {
	var view: some View {
		SkyGradient(solar: self)
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
