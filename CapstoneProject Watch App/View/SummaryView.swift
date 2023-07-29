//
//  ContentView.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/28.
//

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var mainManager: MainManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        if mainManager.calculating {
            ProgressView("Saving workout")
                .navigationBarHidden(true)
        } else {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    SummaryMetricView(
                        title: "Squat",
                        value: String(mainManager.squatCount)
                    ).foregroundStyle(.yellow)
                    SummaryMetricView(
                        title: "Lunge",
                        value: String(mainManager.lungeCount)
                    ).foregroundStyle(.green)
                    SummaryMetricView(
                        title: "Sit up",
                        value: String(mainManager.situpCount)
                    ).foregroundStyle(.pink)
                    SummaryMetricView(
                        title: "Burpee",
                        value: String(mainManager.burpeeCount)
                    ).foregroundStyle(.blue)
                    Button("Done") {
                        dismiss()
                    }
                }
                .scenePadding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
            .environmentObject(MainManager())
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String
    
    var body: some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
        Divider()
    }
}
