//
//  LocationPermissionScreenerView.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import SwiftUI
import TipKit

struct LocationPermissionScreenerView: View {
	@Environment(\.openURL) var openURL
	@EnvironmentObject var currentLocation: CurrentLocation
	
	let tip = WelcomeTip()
	
	var fallbackTipView: some View {
		#if !os(watchOS)
		GroupBox {
			tip.message
		} label: {
			tip.title
		}
		#else
		VStack(alignment: .leading) {
			tip.title.font(.headline)
			tip.message
		}
		#endif
	}
	
	var body: some View {
		Section {
			#if !os(watchOS)
			if #unavailable(iOS 17, macOS 13, visionOS 1) {
				fallbackTipView
			}
			#else
			fallbackTipView
			#endif
			
			Button {
				currentLocation.requestAccess()
				#if os(macOS)
				openURL.callAsFunction(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
				#endif
			} label: {
				Text("Set up location services")
			}
			#if !os(watchOS)
			.modify { content in
				if #available(iOS 17, macOS 14, *) {
					content.popoverTip(WelcomeTip())
				} else {
					content
				}
			}
			#endif
			#if os(iOS)
			.buttonStyle(.borderless)
			#elseif os(macOS)
			.buttonStyle(.bordered)
			#endif
		}
	}
}

struct LocationPermissionScreenerView_Previews: PreviewProvider {
    static var previews: some View {
			Form {
				LocationPermissionScreenerView()
			}
    }
}
