//
//  SettingsView.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
    var body: some View {
			TabView {
				NotificationSettings()
					.frame(idealWidth: 300, idealHeight: 400)
					.tabItem {
						Label("Notifications", systemImage: "app.badge")
					}
				
				SupporterSettings()
					.frame(idealWidth: 300, idealHeight: 600)
					.tabItem {
						Label("About Solstice", systemImage: "heart")
					}
			}
			.formStyle(.grouped)
			.navigationTitle("Settings")
			#if !os(macOS)
			.toolbar {
				Button {
					dismiss()
				} label: {
					Text("Close")
				}
			}
			#endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
