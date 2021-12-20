//
//  NotificationSchedulePicker.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 16/12/2021.
//

import SwiftUI

struct NotificationSchedulePicker: View {
  @AppStorage(UDValues.NotificationSettings.scheduleType) var scheduleType
  @AppStorage(UDValues.NotificationSettings.notificationTime) var notificationTime
  @AppStorage(UDValues.NotificationSettings.relativity) var relativity
  @AppStorage(UDValues.NotificationSettings.relation) var relation
  @AppStorage(UDValues.NotificationSettings.relativeOffset) var relativeOffset
  
  @State private var __notificationTime = Date()
  
  var body: some View {
    Group {
      Picker("Send notifications", selection: $scheduleType) {
        Text(ScheduleType.specificTime.description).tag(ScheduleType.specificTime)
        Text(ScheduleType.relativeTime.description).tag(ScheduleType.relativeTime)
      }
      .onChange(of: scheduleType) { _ in
        NotificationManager.shared.adjustSchedule()
      }
      
      switch scheduleType {
      case .specificTime:
        DatePicker("Notification time", selection: $__notificationTime, displayedComponents: [.hourAndMinute])
          .onChange(of: __notificationTime) { newValue in
            notificationTime = __notificationTime.timeIntervalSince1970
            NotificationManager.shared.adjustSchedule()
          }
          .onAppear {
            __notificationTime = Date(timeIntervalSince1970: notificationTime)
          }
      case .relativeTime:
        DisclosureGroup {
          DurationPicker(duration: $relativeOffset)
            .onChange(of: relativeOffset) { _ in
              NotificationManager.shared.adjustSchedule()
            }
          
          Picker(selection: $relativity) {
            ForEach(ScheduleType.Relativity.allCases, id: \.self) { relativity in
              Text(relativity.description)
            }
          } label: {
            Text("Before/After")
          }
          .onChange(of: relativity) { _ in
            NotificationManager.shared.adjustSchedule()
          }
          
          Picker(selection: $relation) {
            ForEach(ScheduleType.Relation.allCases, id: \.self) { relation in
              Text(relation.description)
            }
          } label: {
            Text("Sunrise/Sunset")
          }
          .onChange(of: relation) { _ in
            NotificationManager.shared.adjustSchedule()
          }
        } label: {
          Text("\(relativeOffset.localizedString) \(relativity.description.localizedLowercase) \(relation.description.localizedLowercase)")
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
