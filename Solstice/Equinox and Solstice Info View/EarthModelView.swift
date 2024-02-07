//
//  EarthModelView.swift
//  Solstice
//
//  Created by Daniel Eden on 04/02/2024.
//

import SwiftUI
import RealityKit

#if os(visionOS)
struct EarthModelView: View {
	var body: some View {
		Model3D(named: "Earth") { model in
			model
				.resizable()
				.aspectRatio(contentMode: .fit)
		} placeholder: {
			ProgressView()
		}
	}
}
#else
struct EarthModelView: View {
	var body: some View {
		EmptyView()
	}
}
#endif

#Preview {
    EarthModelView()
}
