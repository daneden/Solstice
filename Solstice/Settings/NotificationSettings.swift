//
//  NotificationSettings.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI
import Solar
import CoreLocation

fileprivate typealias NotificationFragment = (label: String, value: Binding<Bool>)

struct NotificationSettings: View {
	@AppStorage(Preferences.notificationsEnabled) var notificationsEnabled
	
	@AppStorage(Preferences.NotificationSettings.scheduleType) var scheduleType
	@AppStorage(Preferences.NotificationSettings.relativeOffset) var notificationOffset
	@AppStorage(Preferences.NotificationSettings.notificationTime) var notificationTime
	
	// Notification fragment settings
	@AppStorage(Preferences.notificationsIncludeSunTimes) var notifsIncludeSunTimes
	@AppStorage(Preferences.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
	@AppStorage(Preferences.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
	@AppStorage(Preferences.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
	
	@AppStorage(Preferences.sadPreference) var sadPreference
	
	var timeIntervalFormatter: DateComponentsFormatter {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		return formatter
	}
	
	fileprivate var notificationFragments: [NotificationFragment] {
		[
			(label: "Sunrise/sunset times", value: $notifsIncludeSunTimes),
			(label: "Daylight duration", value: $notifsIncludeDaylightDuration),
			(label: "Daylight gain/loss", value: $notifsIncludeDaylightChange),
			(label: "Time until next solstice", value: $notifsIncludeSolsticeCountdown),
		]
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
				Section {
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
				
				DisclosureGroup {
					ForEach(notificationFragments, id: \.label) { fragment in
						Toggle(fragment.label, isOn: fragment.value)
					}
					
					VStack(alignment: .leading) {
						Text("Notification Preview")
							.font(.caption)
							.foregroundColor(.secondary)
						Text(NotificationManager.buildNotificationContent(for: Date(), location: .init(latitude: 0, longitude: 0), in: .preview)?.body ?? "Preview")
					}.padding(.vertical, 8)
				} label: {
					Text("Customise Notification Content").foregroundColor(.primary)
				}
				
				Section {
					Picker(selection: $sadPreference) {
						ForEach(Preferences.SADPreference.allCases, id: \.self) { sadPreference in
							Text(sadPreference.rawValue)
						}
					} label: {
						Text("SAD Preference")
					}
				} footer: {
					Text("Change how notifications behave when daily daylight begins to decrease. This can help with Seasonal Affective Disorder.")
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
