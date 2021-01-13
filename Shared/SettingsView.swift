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
  
  @AppStorage(UDValues.notificationsEnabled.key, store: solsticeUDStore)
  var notifsEnabled = UDValues.notificationsEnabled.value
  
  @AppStorage(UDValues.notificationTime.key, store: solsticeUDStore)
  var notifTime: TimeInterval = UDValues.notificationTime.value
  
  @State var chosenNotifTime: Date = defaultNotificationDate
  @ObservedObject var notificationManager = NotificationManager.shared
  
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
