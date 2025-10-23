//
//  BalanceApp.swift
//  Balance
//
//  Created by Konstantin Kunth on 23.10.25.
//

import SwiftUI
import CoreData

@main
struct BalanceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
