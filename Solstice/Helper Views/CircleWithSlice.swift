//
//  CircleWithSlice.swift
//  Solstice
//
//  Created by Dan Eden on 16/10/2025.
//

import SwiftUI

struct CircleWithSlice: Shape {
	var startAngle: Double // degrees
	var endAngle: Double // degrees
	
	var animatableData: AnimatablePair<Double, Double> {
		get { AnimatablePair(startAngle, endAngle) }
		set {
			startAngle = newValue.first
			endAngle = newValue.second
		}
	}
	
	func path(in rect: CGRect) -> Path {
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = min(rect.width, rect.height) / 2
		
		var path = Path()
		
		// Draw the full circle
		path.addEllipse(in: rect)
		
		// Create the slice path
		var slice = Path()
		slice.move(to: center)
		slice.addArc(center: center,
								 radius: radius,
								 startAngle: Angle(degrees: startAngle),
								 endAngle: Angle(degrees: endAngle),
								 clockwise: false)
		slice.closeSubpath()
		
		// Subtract the slice from the circle
		path.addPath(slice, transform: .identity)
		path.closeSubpath()
		return path
			.subtracting(slice)
	}
}
