//
//  iConnectDuoApp.swift
//  iConnectDuo
//
//  Created by Chris  on 16/8/25.
//

import SwiftUI

@main
struct iConnectDuoApp: App {
    @StateObject var tabSelection = TabSelection()  // env var share between views
    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationHandler.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabSelection)

        }
    }
}


#Preview {
    ContentView()
}
