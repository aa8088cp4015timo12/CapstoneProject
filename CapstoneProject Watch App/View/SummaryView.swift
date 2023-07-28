//
//  ContentView.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/28.
//

import SwiftUI

struct SummaryView: View {
    var body: some View {
        @EnvironmentObject var mainManager: MainManager
        @Environment(\.dismiss) var dismiss
       var body: some View {
            if mainManager.running {
                ProgressView("Saving Workout")
                    .navigationBarHidden(true)
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        SummaryMetricView(title: "Squat",
                                          value: Measurement(value: mainManager.squatCount)
                            .formatted(.measurement(width: .abbreviated,
                                                    usage: .road,
                                                    numberFormat: .numeric(precision: .fractionLength(2)))))
                        .foregroundStyle(.green)
                        SummaryMetricView(title: "Lunge",
                                          value: Measurement(value: mainManager.LungeCount)
                            .formatted(.measurement(width: .abbreviated,
                                                    usage: .workout,
                                                    numberFormat: .numeric(precision: .fractionLength(0)))))
                        .foregroundStyle(.pink)
                        SummaryMetricView(title: "Sit-up",
                                          value: mainManager.situpCount)
                        .foregroundStyle(.red)
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
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
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
