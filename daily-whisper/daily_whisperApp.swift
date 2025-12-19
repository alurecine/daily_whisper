//
//  daily_whisperApp.swift
//  daily-whisper
//
//  Created by Alan Recine on 19/12/2025.
//

import SwiftUI
import CoreData

@main
struct daily_whisperApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
