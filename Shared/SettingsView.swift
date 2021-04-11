//
//  SettingsView.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 08/01/2021.
//

import SwiftUI
import UserNotifications

typealias NotificationFragment = (label: String, value: Binding<Bool>)

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var notificationManager = NotificationManager.shared
  
  // General notification settings
  @AppStorage(UDValues.notificationsEnabled) var notifsEnabled
  @AppStorage(UDValues.notificationTime) var notifTime
  
  // Notification fragment settings
  @AppStorage(UDValues.notificationsIncludeSunTimes) var notifsIncludeSunTimes
  @AppStorage(UDValues.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
  @AppStorage(UDValues.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
  @AppStorage(UDValues.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
  
  // Local state manager for notification times
  @State var chosenNotifTime: Date = defaultNotificationDate
  
  // Disclosure group visibility toggle
  @State var fragmentSettingsVisible = false
  
  init() {
    chosenNotifTime = Date(timeIntervalSince1970: notifTime)
  }
  
  var notificationFragments: [NotificationFragment] {
    [
      (label: "Sunrise/sunset times", value: $notifsIncludeSunTimes),
      (label: "Daylight duration", value: $notifsIncludeDaylightDuration),
      (label: "Daylight gain/loss", value: $notifsIncludeDaylightChange),
      (label: "Time until next solstice", value: $notifsIncludeSolsticeCountdown),
    ]
  }
  
  var body: some View {
    let viewRemainingDaylightIntent = ViewRemainingDaylightIntent()
    viewRemainingDaylightIntent.suggestedInvocationPhrase = "How much daylight is left today?"
    
    return NavigationView {
      Form {
        Section(
          header: Text("Notifications")
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
          
          DisclosureGroup(
            isExpanded: $fragmentSettingsVisible,
            content: {
              ForEach(notificationFragments, id: \.label) { fragment in
                Toggle(fragment.label, isOn: fragment.value)
                  .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                  .disabled(!notifsEnabled)
              }
              
              VStack(alignment: .leading) {
                Text("Notification Preview")
                  .font(.caption)
                  .foregroundColor(.secondary)
                NotificationPreview()
              }.padding(.vertical, 8)
            },
            label: {
              Button(action: { withAnimation { self.fragmentSettingsVisible.toggle() } }) {
                HStack {
                  Text("Customise Notification Content").foregroundColor(.primary)
                  Spacer()
                }.contentShape(Rectangle())
              }
            }
          )
          
        }
        
        Section(header: Text("Siri")) {
          VStack(alignment: .leading) {
            Text("View Remaining Daylight")
              .padding(.bottom, 1)
            
            Text("Add a shortcut to Siri to quickly find out how much daylight is left.")
              .font(.footnote)
              .foregroundColor(.secondary)
            
            IntentView(intent: viewRemainingDaylightIntent)
              .padding(.bottom, 8)
          }.padding(.vertical, 4)
          
          Button(action: { UIApplication.shared.open(URL(string: "shortcuts://")!) }) {
            Label("Open Shortcuts App", systemImage: "square.2.stack.3d")
          }
          
          Text("Create more Solstice shortcuts in the Shortcuts app").font(.caption).foregroundColor(.secondary)
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
    .onChange(of: notificationFragments.map { $0.value.wrappedValue }) { _ in
      notificationManager.adjustSchedule()
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
