//
//  mimuApp.swift
//  mimu
//
//  Created by Naveen Devang on 3/16/26.
//

import SwiftUI
import SwiftData

@main
struct mimuApp: App {
    var sharedModelContainer: ModelContainer = {
        // Ensure the Application Support directory exists before SwiftData
        // attempts to create its SQLite store file there.
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        let schema = Schema([
            AppTask.self,
            AppEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
