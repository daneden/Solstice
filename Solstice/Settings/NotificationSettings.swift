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
	
	@AppStorage(Preferences.customNotificationLocationUUID) var customNotificationLocationUUID
	
	@AppStorage(Preferences.NotificationSettings.scheduleType) var scheduleType
	@AppStorage(Preferences.NotificationSettings.relativeOffset) var notificationOffset
	@AppStorage(Preferences.NotificationSettings.notificationTime) var notificationTime
	
	// Notification fragment settings
	@AppStorage(Preferences.notificationsIncludeSunTimes) var notifsIncludeSunTimes
	@AppStorage(Preferences.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
	@AppStorage(Preferences.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
	@AppStorage(Preferences.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
	
	@AppStorage(Preferences.sadPreference) var sadPreference
	
	@EnvironmentObject var currentLocation: CurrentLocation
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)],
		animation: .default)
	private var items: FetchedResults<SavedLocation>
	
	fileprivate var notificationFragments: [NotificationFragment] {
		[
			(label: "Sunrise/sunset times", value: $notifsIncludeSunTimes),
			(label: "Daylight duration", value: $notifsIncludeDaylightDuration),
			(label: "Daylight gain/loss", value: $notifsIncludeDaylightChange),
			(label: "Time until next solstice", value: $notifsIncludeSolsticeCountdown),
		]
	}
	
	var body: some View {
		#if os(iOS)
		NavigationStack {
			content
		}
		#else
		content
		#endif
	}
	
	@ViewBuilder
	var content: some View {
		Form {
			Toggle("Enable notifications", isOn: $notificationsEnabled)
				.onChange(of: notificationsEnabled) { _ in
					Task {
						if notificationsEnabled == true {
							notificationsEnabled = await NotificationManager.requestAuthorization() ?? false
						}
					}
				}
			
			Group {
				Section {
					Picker("Location", selection: $customNotificationLocationUUID.animation()) {
						Text("Current location")
							.tag(String?.none)
						ForEach(items) { location in
							if let title = location.title {
								Text(title)
									.tag(location.uuid?.uuidString)
							}
						}
					}
				} footer: {
					if notificationsEnabled && !currentLocation.isAuthorized && customNotificationLocationUUID == nil {
						#if os(iOS)
						if let url = URL(string: UIApplication.openSettingsURLString) {
							VStack(alignment: .leading) {
								Text("You will need to enable location services for Solstice or choose a different location in order to receive notifications.")
								Link("Open app Settings", destination: url)
							}.font(.footnote)
						}
						#else
						Text("You will need to enable location services for Solstice or choose a different location in order to receive notifications.")
						#endif
					}
				}
				
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
									Text("\(Duration.seconds(abs(timeInterval)).formatted(.units(maximumUnitCount: 2))) before")
								case let x where x > 0:
									Text("\(Duration.seconds(timeInterval).formatted(.units(maximumUnitCount: 2))) after")
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
							.font(.footnote)
							.foregroundStyle(.secondary)
						NotificationPreview()
					}
				} label: {
					Text("Customise notification content")
				}
				
				Section {
					Picker(selection: $sadPreference) {
						ForEach(Preferences.SADPreference.allCases, id: \.self) { sadPreference in
							Text(sadPreference.rawValue)
						}
					} label: {
						Text("SAD preference")
					}
				} footer: {
					Text("Change how notifications behave when daily daylight begins to decrease. This can help with Seasonal Affective Disorder.")
				}
			}
			.disabled(!notificationsEnabled)
		}
		.navigationTitle("Notifications")
	}
}

struct NotificationPreview: View {
	var title: String = ""
	var bodyContent: String = ""
	
	init() {
		guard let content = NotificationManager.buildNotificationContent(for: Date(), location: .init(), in: .preview) else {
			return
		}
		
		title = content.title
		bodyContent = content.body
	}
	
	var body: some View {
		HStack {
			Image("notificationPreviewAppIcon")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 20, height: 20)
			
			VStack(alignment: .leading) {
				Text(title).font(.footnote.bold())
				Text(bodyContent).font(.footnote.leading(.tight))
					.fixedSize(horizontal: false, vertical: true)
					.lineLimit(4)
			}
			
			Spacer(minLength: 0)
		}
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.background(.regularMaterial)
		.cornerRadius(12)
	}
}


struct NotificationSettings_Previews: PreviewProvider {
	static var previews: some View {
		NotificationSettings()
	}
}
