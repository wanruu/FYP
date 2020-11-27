//
//  GetMapApp.swift
//  GetMap
//
//  Created by wanruuu on 27/11/2020.
//

import SwiftUI

@main
struct GetMapApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
