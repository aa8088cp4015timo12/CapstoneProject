//
//  StartView.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/28.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject var mainManager: MainManager
    @State private var hasFunctionRun = false
    var body: some View {
        VStack {
            Button{
                mainManager.togglePause()
            } label: {
                Image(systemName: mainManager.running ? "xmark" : "play")
            }
            .tint(mainManager.running ? Color.red : Color.green)
            .font(.title2)
            Text(mainManager.running ? "End" : "Play")
                .onAppear() {
                    if !hasFunctionRun {
                        print("func readModel")
                        mainManager.readModel()
                        hasFunctionRun = true
                    }
                }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
            .environmentObject(MainManager())
    }
}
