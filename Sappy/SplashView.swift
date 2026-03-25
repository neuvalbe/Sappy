//
//  SplashView.swift
//  Sappy
//

import SwiftUI

// MARK: - Splash View (Archived — not currently in active flow)
struct SplashView: View {
    @Binding var appState: AppState
    
    @State private var isDrawing = false
    @State private var isScaling = false
    @State private var logoOpacity = 0.0
    
    // Start with separated faces, gracefully spaced
    @State private var faceSeparation: CGFloat = 60
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZStack {
                // Sad Face: Left Arc + Colon
                // Shifts left initially
                SappyLogoShape(drawLeft: true, drawColon: true, drawRight: false)
                    .trim(from: 0.0, to: isDrawing ? 1.0 : 0.0)
                    .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                    .offset(x: -faceSeparation)

                // Happy Face: Colon + Right Arc
                // Shifts right initially
                SappyLogoShape(drawLeft: false, drawColon: true, drawRight: true)
                    .trim(from: 0.0, to: isDrawing ? 1.0 : 0.0)
                    .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                    .offset(x: faceSeparation)
            }
            .frame(width: 140, height: 140)
            // Apply a single seamless gradient across the moving composite shape
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.2, blue: 0.2), Color(red: 0.8, green: 0.0, blue: 0.0), Color(red: 0.5, green: 0.0, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(isScaling ? 1.15 : 1.0)
            .opacity(logoOpacity)
        }
        .onAppear {
            launchAnimation()
        }
    }
    
    private func launchAnimation() {
        // 1. Elegantly fade in and draw the separated faces over a longer duration
        withAnimation(.easeInOut(duration: 2.5)) {
            logoOpacity = 1.0
            isDrawing = true
        }
        
        // 2. Play soft haptic and do a buttery smooth, 60fps-feeling slide together to merge!
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            
            // Response 1.2 provides a beautiful, slow cinematic sweep
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                faceSeparation = 0 // Merge them physically
                isScaling = true
            }
        }
        
        // 3. Ultra-smooth settle back down with light haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                isScaling = false
            }
        }
        
        // 4. Smoothly crossfade out to the LoginView
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            appState = .login
        }
    }
}
