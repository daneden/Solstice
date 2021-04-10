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
    let content = notificationManager.buildNotificationContent(for: Date())
    title = content.title
    bodyContent = content.body
  }
  
    var body: some View {
      VStack(alignment: .leading) {
        Text(title).font(Font.footnote.bold())
        Text(bodyContent).font(Font.footnote.leading(.tight))
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .background(VisualEffectView.SystemMaterial())
      .cornerRadius(12)
    }
}

struct NotificationPreview_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreview()
    }
}
