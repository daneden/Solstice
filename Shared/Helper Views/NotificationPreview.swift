//
//  NotificationPreview.swift
//  Solstice
//
//  Created by Daniel Eden on 19/01/2021.
//

import SwiftUI

struct NotificationPreview: View {
  let notificationManager = NotificationManager.shared
  var title: String = ""
  var bodyContent: String = ""
  
  init() {
    guard let content = notificationManager.buildNotificationContent(for: Date(), in: .preview) else {
      return
    }
    
    title = content.title
    bodyContent = content.body
  }
  
    var body: some View {
      HStack {
        Image("notificationPreviewAppIcon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 20, height: 20)
        
        VStack(alignment: .leading) {
          Text(title).font(Font.footnote.bold())
          Text(bodyContent).font(Font.footnote.leading(.tight))
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(4)
        }
        
        Spacer(minLength: 0)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .background(.regularMaterial)
      .cornerRadius(12)
    }
}

struct NotificationPreview_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreview()
    }
}
