//
//  NotificationSettings.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI
import Solar

struct NotificationSettings: View {
	@AppStorage(Preferences.NotificationSettings.relativeOffset) var notificationOffset
	@AppStorage(Preferences.NotificationSettings.relation) var relativeEvent
	@AppStorage("hi") var l: Bool?
	
	var timeIntervalFormatter: DateComponentsFormatter {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		return formatter
	}
	
    var body: some View {
			Form {
				Picker(selection: $notificationOffset) {
					ForEach(Preferences.NotificationSettings.relativeOffsetDetents, id: \.self) { timeInterval in
						switch timeInterval {
						case let x where x < 0:
							Text("\(timeIntervalFormatter.string(from: abs(timeInterval)) ?? "") before")
						case let x where x > 0:
							Text("\(timeIntervalFormatter.string(from: timeInterval) ?? "") after")
						default:
							Text("At \(relativeEvent.rawValue)")
						}
					}
				} label: {
					Text("Time relative to \(relativeEvent.rawValue)")
				}
				
				Picker(selection: $relativeEvent) {
					Text("at \(Solar.Phase.sunrise.rawValue)")
						.tag(Solar.Phase.sunrise)
					
					Text("at \(Solar.Phase.sunset.rawValue)")
						.tag(Solar.Phase.sunset)
				} label: {
					Text("Send notifications")
				}
			}

    }
}

struct NotificationSettings_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettings()
    }
}
