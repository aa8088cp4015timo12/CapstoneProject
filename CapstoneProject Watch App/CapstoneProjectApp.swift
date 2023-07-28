//
//  CapstoneProjectApp.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/28.
//

import SwiftUI

@main
struct CapstoneProjectApp: App {
    @StateObject private var mainManager = MainManager()
    var body: some Scene {
        WindowGroup {
            StartView()
                .sheet(isPresented: $mainManager.showingSummaryView) {
                    // SummaryView()
                }
                .environmentObject(mainManager)
        }
    }
}
