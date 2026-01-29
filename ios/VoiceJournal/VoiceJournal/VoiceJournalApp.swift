//
//  VoiceJournalApp.swift
//  VoiceJournal
//
//  Created by Araja  on 1/28/26.
//

import SwiftUI

@main
struct VoiceJournalApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                LaunchView()
            } else if appState.isAuthenticated {
                HubView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: appState.isAuthenticated)
    }
}
