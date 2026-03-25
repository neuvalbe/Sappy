//
//  ContentView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI

// MARK: - Root View

/// The root view of Sappy. Acts as a state-driven router that
/// crossfades between the authentication flow and the mood-tracking experience.
///
/// `AppState` is defined in `SappyDesignTokens.swift`.
struct ContentView: View {
    @State private var appState: AppState = .login

    var body: some View {
        ZStack {
            switch appState {
            case .splash:
                SplashView(appState: $appState)
                    .transition(.opacity)
            case .login:
                LoginView(appState: $appState)
                    .transition(.opacity)
            case .tracking:
                TrackingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: appState)
    }
}

#Preview {
    ContentView()
}
