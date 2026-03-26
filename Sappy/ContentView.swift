//
//  ContentView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import FirebaseAuth

// MARK: - Root View

/// The root view of Sappy. Acts as a state-driven router that
/// crossfades between the authentication flow and the mood-tracking experience.
///
/// On launch, checks `Auth.auth().currentUser` — if the user is already
/// authenticated from a previous session, skips login entirely.
struct ContentView: View {
    /// Resolved synchronously before first render — no `.onAppear` delay,
    /// no one-frame flash. Firebase Auth caches the session in the Keychain
    /// so `currentUser` is non-nil immediately on relaunch.
    @State private var appState: AppState = Auth.auth().currentUser != nil ? .tracking : .login

    var body: some View {
        ZStack {
            switch appState {
            case .login:
                LoginView(appState: $appState)
                    .transition(.opacity)
            case .tracking:
                TrackingView(appState: $appState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: appState)
    }
}

#Preview {
    ContentView()
}
