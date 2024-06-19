//
//  AppChangeMigrator.swift
//  Solstice
//
//  Created by Daniel Eden on 19/06/2024.
//

import SwiftUI

struct AppChangeMigrator: ViewModifier {
	@AppStorage(Preferences.NotificationSettings._notificationTime) var notificationTime
	@AppStorage(Preferences.NotificationSettings.notificationDateComponents) var notificationDateComponents
	
	func body(content: Content) -> some View {
		content
			.task(id: "Notification schedule strategy migrator") {
				if notificationDateComponents == Preferences.NotificationSettings.defaultDateComponents {
					notificationDateComponents = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: notificationTime)
				}
			}
	}
}

extension View {
	func migrateAppFeatures() -> some View {
		self.modifier(AppChangeMigrator())
	}
}
