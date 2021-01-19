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
    let content = notificationManager.buildNotificationContent()
    title = content.title
    bodyContent = content.body
    print(title)
    print(bodyContent)
  }
  
    var body: some View {
      VStack(alignment: .leading) {
        Text(title).font(Font.footnote.bold())
        Text(bodyContent).font(Font.footnote.leading(.tight))
      }
      .padding(8)
      .background(VisualEffectView.SystemMaterial())
      .cornerRadius(12)
    }
}

struct NotificationPreview_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreview()
    }
}
