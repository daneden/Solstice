//
//  NotificationSchedulePicker.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 16/12/2021.
//

import SwiftUI

struct NotificationSchedulePicker: View {
  @AppStorage(UDValues.notificationSettings) var notificationSettings
  
  var body: some View {
    Form {
      Picker("Send notifications", selection: $notificationSettings.scheduleType) {
        Text(ScheduleType.specificTime.rawValue).tag(ScheduleType.specificTime)
        Text(ScheduleType.relativeTime.rawValue).tag(ScheduleType.relativeTime)
      }
      
      switch notificationSettings.scheduleType {
      case .specificTime:
        DatePicker("Notification time", selection: $notificationSettings.notificationDate, displayedComponents: [.hourAndMinute])
      case .relativeTime:
        Group {
          DurationPicker(duration: $notificationSettings.relativeOffset)
        }
      }
    }
  }
}

struct NotificationSchedulePicker_Previews: PreviewProvider {
  static var previews: some View {
    NotificationSchedulePicker()
  }
}
