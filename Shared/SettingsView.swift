//
//  SettingsView.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 08/01/2021.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var notificationManager = NotificationManager.shared
  
  // General notification settings
  @AppStorage(UDValues.notificationsEnabled.key, store: solsticeUDStore)
  var notifsEnabled = UDValues.notificationsEnabled.value
  
  @AppStorage(UDValues.notificationTime.key, store: solsticeUDStore)
  var notifTime: TimeInterval = UDValues.notificationTime.value
  
  // Notification fragment settings
  @AppStorage(UDValues.notificationsIncludeSunTimes.key, store: solsticeUDStore)
  var notifsIncludeSunTimes: Bool = UDValues.notificationsIncludeSunTimes.value
  
  @AppStorage(UDValues.notificationsIncludeDaylightDuration.key, store: solsticeUDStore)
  var notifsIncludeDaylightDuration: Bool = UDValues.notificationsIncludeDaylightDuration.value
  
  @AppStorage(UDValues.notificationsIncludeSolsticeCountdown.key, store: solsticeUDStore)
  var notifsIncludeSolsticeCountdown: Bool = UDValues.notificationsIncludeSolsticeCountdown.value
  
  @AppStorage(UDValues.notificationsIncludeDaylightChange.key, store: solsticeUDStore)
  var notifsIncludeDaylightChange: Bool = UDValues.notificationsIncludeDaylightChange.value
  
  // Local state manager for notification times
  @State var chosenNotifTime: Date = defaultNotificationDate
  
  init() {
    chosenNotifTime = Date(timeIntervalSince1970: notifTime)
  }
  
  var body: some View {
    NavigationView {
      Form {
        Section(
          header: Text("Notifications"),
          footer: Text("Allow Solstice to show daily notifications with the day’s daylight gain/loss.")
        ) {
          Toggle(isOn: $notifsEnabled) {
            Text("Enable Daily Notifications")
          }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
          
          
          DatePicker(
            "Notification Time",
            selection: $chosenNotifTime,
            displayedComponents: [.hourAndMinute]
          ).onChange(of: chosenNotifTime) { _ in
            notifTime = chosenNotifTime.timeIntervalSince1970
            notificationManager.adjustSchedule()
          }.disabled(!notifsEnabled)
          
          DisclosureGroup("Notification Content") {
            // TODO: Make this code dry-er
            Toggle(NotificationFragments.sunriseAndSunsetTimes.rawValue, isOn: $notifsIncludeSunTimes)
              .toggleStyle(SwitchToggleStyle(tint: .accentColor))
              .disabled(!notifsEnabled)
            
            Toggle(NotificationFragments.daylightDuration.rawValue, isOn: $notifsIncludeDaylightDuration)
              .toggleStyle(SwitchToggleStyle(tint: .accentColor))
              .disabled(!notifsEnabled)
            
            Toggle(NotificationFragments.daylightChange.rawValue, isOn: $notifsIncludeDaylightChange)
              .toggleStyle(SwitchToggleStyle(tint: .accentColor))
              .disabled(!notifsEnabled)
            
            Toggle(NotificationFragments.timeUntilNextSolstice.rawValue, isOn: $notifsIncludeSolsticeCountdown)
              .toggleStyle(SwitchToggleStyle(tint: .accentColor))
              .disabled(!notifsEnabled)
            
          }.onChange(of: [notifsIncludeDaylightChange, notifsIncludeSolsticeCountdown, notifsIncludeSunTimes, notifsIncludeDaylightDuration]) { _ in
            self.notificationManager.adjustSchedule()
          }
            
        }
      }
      .navigationTitle(Text("Settings"))
      .toolbar {
        ToolbarItem {
          Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
            Text("Close")
          }
        }
      }
      .onAppear {
        chosenNotifTime = Date(timeIntervalSince1970: notifTime)
      }
      .onChange(of: notifsEnabled) { value in
        /** To prevent duplicated calls, we'll only call this method when the toggle is on */
        if value {
          notificationManager.toggleNotifications(on: value, bindingTo: $notifsEnabled)
        }
      }
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
