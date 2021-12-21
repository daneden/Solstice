//
//  SettingsView.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 08/01/2021.
//

import SwiftUI
import UserNotifications

#if os(iOS)
import StoreKit
#endif

typealias NotificationFragment = (label: String, value: Binding<Bool>)

struct SettingsView: View {
  @AppStorage("sessionCount") var sessionCount = 0
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var notificationManager = NotificationManager.shared
  
  // General notification settings
  @AppStorage(UDValues.notificationsEnabled) var notifsEnabled
  @AppStorage(UDValues.NotificationSettings.notificationTime) var notifTime
  
  // Notification fragment settings
  @AppStorage(UDValues.notificationsIncludeSunTimes) var notifsIncludeSunTimes
  @AppStorage(UDValues.notificationsIncludeDaylightDuration) var notifsIncludeDaylightDuration
  @AppStorage(UDValues.notificationsIncludeSolsticeCountdown) var notifsIncludeSolsticeCountdown
  @AppStorage(UDValues.notificationsIncludeDaylightChange) var notifsIncludeDaylightChange
  @AppStorage(UDValues.sadPreference) var sadPreference
  
  // Local state manager for notification times
  @State var chosenNotifTime: Date = defaultNotificationDate
  
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
          Toggle(isOn: $notifsEnabled.animation()) {
            Text("Enable Daily Notifications")
          }
        }
        
        if notifsEnabled {
          Section {
            NotificationSchedulePicker()
            
            DisclosureGroup {
              ForEach(notificationFragments, id: \.label) { fragment in
                Toggle(fragment.label, isOn: fragment.value)
              }
              
              VStack(alignment: .leading) {
                Text("Notification Preview")
                  .font(.caption)
                  .foregroundColor(.secondary)
                NotificationPreview()
              }.padding(.vertical, 8)
            } label: {
              Text("Customise Notification Content").foregroundColor(.primary)
            }
          }
          
          Section(footer: Text("Change how notifications behave when daily daylight begins to decrease. This can help with Seasonal Affective Disorder.")) {
            Picker("SAD Adjustment", selection: $sadPreference) {
              Section {
                ForEach(SADPreference.allCases, id: \.self) { preference in
                  Text(preference.rawValue)
                }
              }
            }
          }
        }
        
        Section {
          NavigationLink(destination: AboutSolsticeView()) {
            Label("About Solstice", systemImage: "info.circle")
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
    .onChange(of: sadPreference) { _ in
      notificationManager.adjustSchedule()
    }
    .onDisappear {
      sessionCount += 1
      
#if os(iOS)
      if sessionCount >= 3,
         let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          SKStoreReviewController.requestReview(in: windowScene)
        }
      }
#endif
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
