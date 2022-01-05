//
//  ComplicationController.swift
//  WatchSolstice WatchKit Extension
//
//  Created by Daniel Eden on 27/09/2021.
//

import ClockKit
import SwiftUI
import Solar

let sundialSupportedFamilies: [CLKComplicationFamily] = [
  .graphicRectangular,
  .graphicBezel,
  .graphicCircular,
  .graphicExtraLarge
]

let solarEventSupportedFamilies: [CLKComplicationFamily] = [
  .graphicCorner,
  .graphicCircular,
  .modularSmall,
  .circularSmall,
  .utilitarianSmall,
  .utilitarianSmallFlat,
  .utilitarianLarge,
  .modularLarge
]

enum ComplicationKind: String, CaseIterable, RawRepresentable {
  case sundial, solarEvent
}

class ComplicationController: NSObject, CLKComplicationDataSource {
  private let locationManager = LocationManager.shared
  
  // MARK: - Complication Configuration
  func complicationDescriptors() async -> [CLKComplicationDescriptor] {
    let descriptors = [
      CLKComplicationDescriptor(identifier: ComplicationKind.sundial.rawValue, displayName: "Sundial", supportedFamilies: sundialSupportedFamilies),
      CLKComplicationDescriptor(identifier: ComplicationKind.solarEvent.rawValue, displayName: "Solar Event", supportedFamilies: solarEventSupportedFamilies)
    ]
    
    // Call the handler with the currently supported complication descriptors
    return descriptors
  }
  
  // MARK: - Timeline Configuration
  func timelineEndDate(for complication: CLKComplication) async -> Date? {
    // Indicate that the app can provide timeline entries until 24hrs from now.
    return Date().addingTimeInterval(24 * 60 * 60)
  }
  
  func privacyBehavior(for complication: CLKComplication) async -> CLKComplicationPrivacyBehavior {
    // Call the handler with your desired behavior when the device is locked
    return .showOnLockScreen
  }
  
  func timelineAnimationBehavior(for complication: CLKComplication) async -> CLKComplicationTimelineAnimationBehavior {
    return .always
  }
  
  // MARK: - Timeline Population
  func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
    return createTimelineEntry(for: complication, date: .now)
  }
  
  func timelineEntries(for complication: CLKComplication, after date: Date, limit: Int) async -> [CLKComplicationTimelineEntry]? {
    let increment = 20.0 * 60.0
    let calculator = SolarCalculator(baseDate: date)
    
    // Create an array to hold the timeline entries.
    var entries: [CLKComplicationTimelineEntry] = []
    
    // Begin by adding key events to the timeline
    if let sunriseTimelineEntry = createTimelineEntry(for: complication, date: calculator.today.begins.addingTimeInterval(1)),
       let sunsetTimelineEntry = createTimelineEntry(for: complication, date: calculator.today.ends.addingTimeInterval(1)) {
      entries.append(contentsOf: [
        sunriseTimelineEntry,
        sunsetTimelineEntry,
      ])
    }
    
    // Calculate the start and end dates.
    var current = date.addingTimeInterval(increment)
    guard let endDate = await timelineEndDate(for: complication) else {
      return nil
    }
    
    // Create a timeline entry for every ten minutes from the starting time.
    // Stop once you reach the limit or the end date.
    while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
      if let entry = createTimelineEntry(for: complication, date: current) {
        entries.append(entry)
      }
      current = current.addingTimeInterval(increment)
    }
    
    return entries.sorted { $0.date < $1.date }
  }
  
  // MARK: - Sample Templates
  func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
    // This method will be called once per supported complication, and the results will be cached
    switch complication.identifier {
    case ComplicationKind.solarEvent.rawValue:
      return getSolarEventComplicationTemplate(for: complication.family)
    case ComplicationKind.sundial.rawValue:
      return getSundialComplicationTemplate(for: complication.family)
    default:
      return nil
    }
  }
}

extension ComplicationController {
  func createTimelineEntry(for complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry? {
    let template: CLKComplicationTemplate?
    
    switch complication.identifier {
    case ComplicationKind.solarEvent.rawValue:
      template = getSolarEventComplicationTemplate(for: complication.family, at: date)
    case ComplicationKind.sundial.rawValue:
      template = getSundialComplicationTemplate(for: complication.family, at: date)
    default:
      template = nil
    }
    
    if let template = template {
      return CLKComplicationTimelineEntry(
        date: date,
        complicationTemplate: template
      )
    } else {
      return nil
    }
  }
  
  func getSolarEventComplicationTemplate(for family: CLKComplicationFamily, at date: Date = .now) -> CLKComplicationTemplate? {
    guard let solar = Solar(for: date, coordinate: locationManager.coordinate) else {
      return nil
    }
    
    let solarEvent = solar.nextSolarEvent
    
    let eventString: String
    let viewIconName: String
    
    switch solarEvent {
    case .sunrise(_):
      viewIconName = "sunrise.fill"
      eventString = "Sunrise"
    case .sunset(_):
      viewIconName = "sunset.fill"
      eventString = "Sunset"
    }
    
    let textProvider: CLKTextProvider
    
    switch family {
    case .utilitarianLarge, .modularLarge:
      textProvider = CLKTextProvider(format: "\(eventString) at \(solarEvent.date.formatted(date: .omitted, time: .shortened))")
    default:
      textProvider = CLKTimeTextProvider(date: solarEvent.date)
    }
    
    let imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: viewIconName)!)
    let icon = Image(systemName: viewIconName).symbolRenderingMode(.hierarchical)
    
    switch family {
    case .graphicCorner:
      return CLKComplicationTemplateGraphicCornerTextView(
        textProvider: textProvider,
        label: icon
      )
    case .graphicCircular:
      return CLKComplicationTemplateGraphicCircularStackViewText(
        content: icon,
        textProvider: textProvider
      )
    case .modularSmall:
      return CLKComplicationTemplateModularSmallStackImage(
        line1ImageProvider: imageProvider,
        line2TextProvider: textProvider
      )
    case .circularSmall:
      return CLKComplicationTemplateCircularSmallStackImage(
        line1ImageProvider: imageProvider,
        line2TextProvider: textProvider
      )
    case .utilitarianSmall, .utilitarianSmallFlat:
      return CLKComplicationTemplateUtilitarianSmallFlat(
        textProvider: textProvider,
        imageProvider: imageProvider
      )
    case .utilitarianLarge:
      return CLKComplicationTemplateUtilitarianLargeFlat(
        textProvider: textProvider,
        imageProvider: imageProvider
      )
    case .modularLarge:
      return CLKComplicationTemplateModularLargeStandardBody(
        headerImageProvider: imageProvider,
        headerTextProvider: CLKRelativeDateTextProvider(date: solarEvent.date, style: .natural, units: [.hour, .minute, .second]),
        body1TextProvider: textProvider
      )
    default:
      return nil
    }
  }
  
  func getSundialComplicationTemplate(for family: CLKComplicationFamily, at date: Date = .now) -> CLKComplicationTemplate? {
    let calculator = SolarCalculator(baseDate: date, locationManager: locationManager)
    let today = calculator.today
    
    let sunSize: CGFloat
    
    switch family {
    case .graphicCircular, .graphicBezel:
      sunSize = 6
    case .graphicExtraLarge:
      sunSize = 16
    default:
      sunSize = 8
    }
    
    let sundial = SundialView(sunSize: sunSize, trackWidth: 1.5).environmentObject(calculator)
    
    let rectangularSundialView = ZStack(alignment: .bottom) {
      HStack {
        HStack {
          Image(systemName: "sunrise")
          Text(today.begins.formatted(date: .omitted, time: .shortened))
        }
        Spacer()
        
        HStack {
          Text(today.ends.formatted(date: .omitted, time: .shortened))
          Image(systemName: "sunset")
        }
      }
      .font(.caption2)
      .imageScale(.small)
      .symbolVariant(.fill)
      .symbolRenderingMode(.hierarchical)
      
      sundial
        .foregroundStyle(.primary, .secondary)
    }
    
    switch family {
    case .graphicRectangular:
      return CLKComplicationTemplateGraphicRectangularFullView(rectangularSundialView)
    case .graphicCircular:
      return CLKComplicationTemplateGraphicCircularView(sundial.ellipticalEdgeMask())
    case .graphicExtraLarge:
      return CLKComplicationTemplateGraphicExtraLargeCircularView(sundial.ellipticalEdgeMask())
    case .graphicBezel:
      let textProvider: CLKTextProvider
      
      switch today.nextSolarEvent {
      case .sunrise(let at):
        textProvider = CLKTextProvider(format: "Sunrise \(at.formatted(.relative(presentation: .named)))")
      case .sunset(let at):
        textProvider = CLKTextProvider(format: "Sunset \(at.formatted(.relative(presentation: .named)))")
      }
      
      return CLKComplicationTemplateGraphicBezelCircularText(
        circularTemplate: CLKComplicationTemplateGraphicCircularView(sundial),
        textProvider: textProvider
      )
    default:
      return nil
    }
  }
}
