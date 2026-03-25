//
//  ContentView.swift
//  Sappy
//

import SwiftUI

// MARK: - App State
enum AppState {
    case splash
    case login
    case tracking
}

// MARK: - Main ContentView
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
