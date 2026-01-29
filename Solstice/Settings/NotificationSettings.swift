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
	@AppStorage(Preferences.NotificationSettings.notificationDateComponents) var notificationDateComponents
	
	// Notification fragment settings
	@AppStorage(Preferences.notificationsIncludeSunTimes) var notifsIncludeSunTimes
	@AppStorage(Preferences.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
	@AppStorage(Preferences.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
	@AppStorage(Preferences.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
	
	@AppStorage(Preferences.sadPreference) var sadPreference
	
	@Environment(CurrentLocation.self) var currentLocation
	
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
	
	private var notificationTime: Binding<Date> {
		Binding {
			let hour = notificationDateComponents.hour ?? 0
			let minute = notificationDateComponents.minute ?? 0
			return Calendar.autoupdatingCurrent.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
		} set: {
			notificationDateComponents = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .timeZone], from: $0)
		}
	}
	
	var body: some View {
		Form {
			enableSection
			settingsGroup
		}
		.navigationTitle("Notifications")
		.formStyle(.grouped)
	}

	private var enableSection: some View {
		Section {
			Toggle("Enable notifications", isOn: $notificationsEnabled)
				.task(id: notificationsEnabled) {
					if notificationsEnabled == true {
						notificationsEnabled = await NotificationManager.requestAuthorization() ?? false
					}
				}
		}
	}

	private var settingsGroup: some View {
		Group {
			locationSection
			scheduleSection
			contentCustomizationGroup
			sadPreferenceSection
		}
		.disabled(!notificationsEnabled)
	}

	private var locationSection: some View {
		Section {
			Picker("Location", selection: $customNotificationLocationUUID.animation()) {
				locationPickerContent
			}
		}
	}

	@ViewBuilder
	private var locationPickerContent: some View {
		if currentLocation.isAuthorized {
			Text("Current location")
				.tag(String?.none)
		} else if customNotificationLocationUUID == nil {
			Text("Select location")
				.tag(String?.none)
				.disabled(true)
		}
		ForEach(items) { location in
			if let title = location.title {
				Text(title)
					.tag(location.uuid?.uuidString)
			}
		}
	}

	private var scheduleSection: some View {
		Section {
			scheduleTypePicker
			scheduleTimePicker
		}
	}

	private var scheduleTypePicker: some View {
		Picker(selection: $scheduleType) {
			ForEach(Preferences.NotificationSettings.ScheduleType.allCases, id: \.self) { type in
				Text(type.description)
			}
		} label: {
			Text("Send at")
		}
	}

	@ViewBuilder
	private var scheduleTimePicker: some View {
		if scheduleType == .specificTime {
			DatePicker(selection: notificationTime, displayedComponents: [.hourAndMinute]) {
				Text("Time")
			}
		} else {
			relativeOffsetPicker
		}
	}

	private var relativeOffsetPicker: some View {
		Picker(selection: $notificationOffset) {
			ForEach(Preferences.NotificationSettings.relativeOffsetDetents, id: \.self) { timeInterval in
				relativeOffsetLabel(for: timeInterval)
			}
		} label: {
			Text("Time")
		}
	}

	private func relativeOffsetLabel(for timeInterval: TimeInterval) -> some View {
		let text: Text
		if timeInterval < 0 {
			text = Text("\(Duration.seconds(abs(timeInterval)).formatted(.units(maximumUnitCount: 2))) before")
		} else if timeInterval > 0 {
			text = Text("\(Duration.seconds(timeInterval).formatted(.units(maximumUnitCount: 2))) after")
		} else {
			text = Text("at \(Text(scheduleType.description))")
		}
		return text
	}

	private var contentCustomizationGroup: some View {
		DisclosureGroup {
			ForEach(notificationFragments, id: \.label) { fragment in
				Toggle(LocalizedStringKey(fragment.label), isOn: fragment.value)
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
	}

	private var sadPreferenceSection: some View {
		Section {
			Picker(selection: $sadPreference) {
				ForEach(Preferences.SADPreference.allCases, id: \.self) { pref in
					Text(pref.description)
				}
			} label: {
				Text("SAD preference")
			}
		} footer: {
			Text("Change how notifications behave when daily daylight begins to decrease. This can help with Seasonal Affective Disorder.")
		}
	}
}

struct NotificationPreview: View {
	var title: String = ""
	var bodyContent: String = ""
	
	init() {
		guard let content = NotificationManager.buildNotificationContent(for: NotificationManager.getNextNotificationDate(after: Date()), location: .init(), in: .preview) else {
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
					.contentTransition(.interpolate)
			}
			
			Spacer(minLength: 0)
		}
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.background(.regularMaterial)
		.cornerRadius(12)
		.animation(.default, value: bodyContent)
	}
}


struct NotificationSettings_Previews: PreviewProvider {
	static var previews: some View {
		NotificationSettings()
	}
}
