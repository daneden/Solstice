//
//  ComplicationController.swift
//  WatchSolstice WatchKit Extension
//
//  Created by Daniel Eden on 27/09/2021.
//

import ClockKit
import SwiftUI

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

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "sundial", displayName: "Sundial", supportedFamilies: sundialSupportedFamilies),
            CLKComplicationDescriptor(identifier: "solarEvent", displayName: "Solar Event", supportedFamilies: solarEventSupportedFamilies)
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
      let template: CLKComplicationTemplate?
      
      switch complication.identifier {
      case "solarEvent":
        template = getSolarEventComplicationTemplate(for: complication.family)
      case "sundial":
        template = getSundialComplicationTemplate(for: complication.family)
      default:
        template = nil
      }
      
      if let template = template {
        handler(CLKComplicationTimelineEntry(
          date: Date(),
          complicationTemplate: template
        ))
      } else {
        handler(nil)
      }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }

    // MARK: - Sample Templates
    
  func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
      // This method will be called once per supported complication, and the results will be cached
    switch complication.identifier {
    case "solarEvent":
      handler(getSolarEventComplicationTemplate(for: complication.family))
    case "sundial":
      handler(getSundialComplicationTemplate(for: complication.family))
    default:
      handler(nil)
    }
  }
  
  func getSolarEventComplicationTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
    let viewIconName: String
    
    let solarEvent = SolarCalculator.shared.getNextSolarEvent()
    
    let textProvider: CLKTextProvider
    
    let eventString: String
    
    switch solarEvent {
    case .sunrise(_):
      viewIconName = "sunrise.fill"
      eventString = "Sunrise"
    case .sunset(_):
      viewIconName = "sunset.fill"
      eventString = "Sunset"
    }
    
    switch family {
    case .utilitarianLarge, .modularLarge:
      textProvider = CLKTextProvider(format: "\(eventString) at \(solarEvent.date().formatted(date: .omitted, time: .shortened))")
    default:
      textProvider = CLKTimeTextProvider(date: solarEvent.date())
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
        headerTextProvider: CLKRelativeDateTextProvider(date: solarEvent.date(), style: .natural, units: [.hour, .minute, .second]),
        body1TextProvider: textProvider
      )
    default:
      return nil
    }
  }
  
  func getSundialComplicationTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
    let today = SolarCalculator.shared.today
    
    let sunSize: CGFloat
    
    switch family {
    case .graphicCircular, .graphicBezel:
      sunSize = 6
    case .graphicExtraLarge:
      sunSize = 16
    default:
      sunSize = 8
    }
    
    let sundial = SundialView(sunSize: sunSize, trackWidth: 2)
    
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
      
      sundial
        .padding(.bottom, sunSize)
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
      let formatter = RelativeDateTimeFormatter()
      
      switch SolarCalculator.shared.getNextSolarEvent() {
      case .sunrise(let at):
        textProvider = CLKTextProvider(format: "Sunrise \(formatter.localizedString(for: at, relativeTo: .now))")
      case .sunset(let at):
        textProvider = CLKTextProvider(format: "Sunset \(formatter.localizedString(for: at, relativeTo: .now))")
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
