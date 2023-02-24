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
	@AppStorage(Preferences.NotificationSettings.scheduleType) var scheduleType
	@AppStorage(Preferences.NotificationSettings.notificationTime) var notificationTime
	@AppStorage(Preferences.notificationsEnabled) var notificationsEnabled
	
	var timeIntervalFormatter: DateComponentsFormatter {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		return formatter
	}
	
    var body: some View {
			Form {
				Toggle("Enable notifications", isOn: $notificationsEnabled)
					.onChange(of: notificationsEnabled) { newValue in
						Task {
							if newValue == true {
								notificationsEnabled = await NotificationManager.requestAuthorization() ?? false
							}
						}
					}
				
				Group {
					Picker(selection: $scheduleType) {
						ForEach(Preferences.NotificationSettings.ScheduleType.allCases, id: \.self) { scheduleType in
							Text(scheduleType.description)
						}
					} label: {
						Text("Send at")
					}
					
					if scheduleType == .specificTime {
						DatePicker(selection: $notificationTime, displayedComponents: [.hourAndMinute]) {
							Text("Time")
						}
					} else {
						Picker(selection: $notificationOffset) {
							ForEach(Preferences.NotificationSettings.relativeOffsetDetents, id: \.self) { timeInterval in
								switch timeInterval {
								case let x where x < 0:
									Text("\(timeIntervalFormatter.string(from: abs(timeInterval)) ?? "") before")
								case let x where x > 0:
									Text("\(timeIntervalFormatter.string(from: timeInterval) ?? "") after")
								default:
									Text("at \(scheduleType.description)")
								}
							}
						} label: {
							Text("Time")
						}
					}
				}
				.disabled(!notificationsEnabled)
			}
    }
}

struct NotificationSettings_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettings()
    }
}
