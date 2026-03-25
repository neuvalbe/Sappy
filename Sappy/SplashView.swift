//
//  SplashView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

// ┌──────────────────────────────────────────────────────────────────┐
// │  ARCHIVED — This view is not in the active navigation flow.     │
// │  Retained for potential reintroduction of the cinematic          │
// │  face-merge entrance animation. The app launches directly       │
// │  into `LoginView` via `AppState.login`.                         │
// └──────────────────────────────────────────────────────────────────┘

import SwiftUI

/// A cinematic splash screen that draws two separated faces and merges them.
///
/// **Status**: Archived. `ContentView` initializes `appState` to `.login`,
/// bypassing this view entirely. The `AppState.splash` case is preserved
/// in the enum for forward compatibility.
struct SplashView: View {
    @Binding var appState: AppState

    // MARK: - Animation State

    @State private var isDrawing = false
    @State private var isScaling = false
    @State private var logoOpacity = 0.0
    @State private var faceSeparation: CGFloat = 60

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZStack {
                // Sad Face: Left Arc + Colon (shifts left initially)
                SappyLogoShape(drawLeft: true, drawColon: true, drawRight: false)
                    .trim(from: 0.0, to: isDrawing ? 1.0 : 0.0)
                    .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                    .offset(x: -faceSeparation)

                // Happy Face: Colon + Right Arc (shifts right initially)
                SappyLogoShape(drawLeft: false, drawColon: true, drawRight: true)
                    .trim(from: 0.0, to: isDrawing ? 1.0 : 0.0)
                    .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                    .offset(x: faceSeparation)
            }
            .frame(width: 140, height: 140)
            .foregroundStyle(SappyDesign.brandGradient)
            .scaleEffect(isScaling ? 1.15 : 1.0)
            .opacity(logoOpacity)
        }
        .onAppear {
            launchAnimation()
        }
    }

    // MARK: - Animation Sequence

    /// Orchestrates the 4-phase splash entrance:
    /// 1. Draw separated faces (2.5s)
    /// 2. Merge with spring physics + haptic (at 2.0s)
    /// 3. Settle scale (at 2.8s)
    /// 4. Crossfade to login (at 4.5s)
    private func launchAnimation() {
        withAnimation(.easeInOut(duration: 2.5)) {
            logoOpacity = 1.0
            isDrawing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                faceSeparation = 0
                isScaling = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                isScaling = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            appState = .login
        }
    }
}
