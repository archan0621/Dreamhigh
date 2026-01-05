//
//  DreamhighApp.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/2/26.
//

import SwiftUI

@main
struct DreamhighApp: App {
    
    private let persistence = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
