//
//  CalendarComponent+Extra.swift
//  Solstice
//
//  Created by Daniel Eden on 15/12/2021.
//

import Foundation

extension Calendar.Component: CaseIterable {
  public static var allCases: [Calendar.Component] {
    [
      .second,
      .hour,
      .minute,
      .month,
      .year,
      .day,
      .calendar,
      .era,
      .nanosecond,
      .quarter,
      .timeZone,
      .weekday,
      .weekdayOrdinal,
      .weekOfYear,
      .weekOfMonth,
      .yearForWeekOfYear
    ]
  }
}
