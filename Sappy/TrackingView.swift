//
//  TrackingView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI

// MARK: - Tracking View

/// The core mood-tracking experience — a cinematic, physics-based interaction.
///
/// ## State Machine
/// The view progresses through four phases:
/// 1. **Draw**: The merged `):)` logo draws via `.trim()` path animation (1.5s).
/// 2. **Split**: A spring pulls the logo apart vertically into `:)` (top) and `:(` (bottom).
/// 3. **Select**: User taps a face → selected face scales up with brand gradient,
///    dismissed face slides off-screen, feedback content fades in.
/// 4. **Reset**: "Change my answer" reverses the selection with spring physics.
///
/// ## Layout
/// Both faces are positioned via `splitOffset` from center. Invisible tap targets
/// cover the top and bottom halves of the screen. A subtle breathing animation
/// keeps the idle state alive.
///
/// ## Data
/// `happyCount` and `sadCount` are currently mocked. They will be replaced
/// with Firestore snapshot listeners during backend integration.
struct TrackingView: View {

    // MARK: - State & Data

    @State private var selectedMood: Mood? = nil

    /// Mocked real-time global counts. Will be replaced with Firestore listeners.
    @State private var happyCount: Int = 12847
    @State private var sadCount: Int = 4392

    // MARK: - Animation Properties

    /// Path trim progress for the initial logo draw (0 → 1).
    @State private var entryTrim: CGFloat = 0.0

    /// Vertical distance each face has traveled from center.
    @State private var splitOffset: CGFloat = 0.0

    /// Opacity of supporting text (mood words, center label).
    @State private var textOpacity: Double = 0.0

    /// Organic idle breathing — vertical offset oscillation.
    @State private var breathingOffset: CGFloat = 0.0

    /// Organic idle breathing — scale oscillation.
    @State private var breathingScale: CGFloat = 1.00

    /// Controls the staggered fade-in of feedback content after mood selection.
    @State private var showFeedbackText: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // MARK: Invisible Touch Targets

            if selectedMood == nil && splitOffset > 100 {
                VStack(spacing: 0) {
                    Color.white.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { selectMood(.happy) }

                    Color.white.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { selectMood(.sad) }
                }
            }

            // MARK: Top Face — Happy :)

            VStack(spacing: 24) {
                SappyLogoShape(drawLeft: false, drawColon: true, drawRight: true)
                    .trim(from: 0, to: entryTrim)
                    .stroke(
                        selectedMood == .happy
                            ? AnyShapeStyle(SappyDesign.brandGradient)
                            : AnyShapeStyle(Color.black.opacity(0.85)),
                        style: StrokeStyle(lineWidth: SappyDesign.trackingStrokeWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: SappyDesign.trackingFaceSize, height: SappyDesign.trackingFaceSize)
                    .scaleEffect(selectedMood == .happy ? SappyDesign.selectedFaceScale : 1.0)

                Text("happy.")
                    .font(.custom(SappyDesign.fontFamily, size: 48))
                    .fontWeight(.light)
                    .italic()
                    .kerning(1.5)
                    .foregroundColor(Color.black.opacity(0.85))
                    .opacity(selectedMood == nil ? textOpacity : 0)
            }
            .scaleEffect(selectedMood == nil ? breathingScale : 1.0)
            .offset(y: selectedMood == .happy
                    ? SappyDesign.selectedFaceOffset
                    : (selectedMood == .sad ? -SappyDesign.dismissedFaceOffset : -splitOffset + breathingOffset))
            .opacity(selectedMood == .sad ? 0 : 1)
            .zIndex(selectedMood == .happy ? 10 : 1)

            // MARK: Bottom Face — Sad :(

            VStack(spacing: 24) {
                SappyLogoShape(drawLeft: true, drawColon: true, drawRight: false)
                    .trim(from: 0, to: entryTrim)
                    .stroke(
                        selectedMood == .sad
                            ? AnyShapeStyle(SappyDesign.brandGradient)
                            : AnyShapeStyle(Color.black.opacity(0.85)),
                        style: StrokeStyle(lineWidth: SappyDesign.trackingStrokeWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: SappyDesign.trackingFaceSize, height: SappyDesign.trackingFaceSize)
                    .scaleEffect(selectedMood == .sad ? SappyDesign.selectedFaceScale : 1.0)

                Text("sad.")
                    .font(.custom(SappyDesign.fontFamily, size: 48))
                    .fontWeight(.light)
                    .italic()
                    .kerning(1.5)
                    .foregroundColor(Color.black.opacity(0.85))
                    .opacity(selectedMood == nil ? textOpacity : 0)
            }
            .scaleEffect(selectedMood == nil ? (2.0 - breathingScale) : 1.0)
            .offset(y: selectedMood == .sad
                    ? SappyDesign.selectedFaceOffset
                    : (selectedMood == .happy ? SappyDesign.dismissedFaceOffset : splitOffset - breathingOffset))
            .opacity(selectedMood == .happy ? 0 : 1)
            .zIndex(selectedMood == .sad ? 10 : 1)

            // MARK: Center Label

            Text("No app asks you how you feel.")
                .font(.custom(SappyDesign.fontFamily, size: 16))
                .foregroundColor(Color.black.opacity(SappyDesign.textQuaternaryOpacity))
                .kerning(1.2)
                .opacity(selectedMood == nil ? textOpacity : 0)

            // MARK: Feedback Content

            if let mode = selectedMood {
                feedbackContent(for: mode)
                    .offset(y: SappyDesign.feedbackContentOffset)
                    .opacity(showFeedbackText ? 1 : 0)
            }
        }
        .onAppear {
            launchCinematicEntrance()
        }
    }

    // MARK: - Cinematic Entrance Sequence

    /// Orchestrates the 4-phase cinematic entrance:
    /// 1. Draw the merged logo via `.trim()` (0 → 1 over 1.5s)
    /// 2. Split faces vertically with spring physics + soft haptic (at 1.2s)
    /// 3. Fade in typography (at 1.8s)
    /// 4. Start organic breathing animation (at 2.4s)
    private func launchCinematicEntrance() {
        // Phase 1: Draw the merged logo
        withAnimation(.easeOut(duration: 1.5)) {
            entryTrim = 1.0
        }

        // Phase 2: Spring-split into faces
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
                splitOffset = SappyDesign.splitDistance
            }
        }

        // Phase 3: Reveal text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 1.0)) {
                textOpacity = 1.0
            }
        }

        // Phase 4: Organic breathing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                breathingOffset = 8
                breathingScale = 1.02
            }
        }
    }

    // MARK: - Mood Selection

    /// Handles user tapping a mood face.
    ///
    /// Fires a rigid haptic, triggers the spring transition to the selected state,
    /// and begins the staggered feedback fade-in.
    private func selectMood(_ mood: Mood) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            selectedMood = mood
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                showFeedbackText = true
            }
        }
    }

    /// Resets the mood selection, animating back to the split idle state.
    private func resetMood() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.easeOut(duration: 0.4)) {
            showFeedbackText = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                selectedMood = nil
            }
        }
    }

    // MARK: - Feedback Content

    /// Builds the post-selection feedback view with staggered animations.
    @ViewBuilder
    private func feedbackContent(for mode: Mood) -> some View {
        VStack(spacing: 32) {

            // Empathetic headline + body
            VStack(spacing: 24) {
                Text(mode == .happy ? "That's wonderful." : "Take a deep breath.")
                    .font(.custom(SappyDesign.fontFamily, size: 34))
                    .fontWeight(.light)
                    .kerning(1.2)
                    .foregroundColor(.black.opacity(0.9))

                Text(mode == .happy
                     ? "Keep riding the wave.\nThe world is yours today."
                     : "It is completely okay to feel this way.\nTomorrow is a new start.")
                    .font(.custom(SappyDesign.fontFamily, size: 18))
                    .foregroundColor(.black.opacity(SappyDesign.textSecondaryOpacity))
                    .kerning(0.8)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            .offset(y: showFeedbackText ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.1), value: showFeedbackText)

            Spacer().frame(height: 10)

            // Real-time counter (mocked)
            let count = mode == .happy ? happyCount : sadCount

            VStack(spacing: 8) {
                Text("\(count.formatted()) people")
                    .font(.custom(SappyDesign.fontFamily, size: 24))
                    .foregroundColor(.black.opacity(0.85))

                Text("feel \(mode.rawValue) right now")
                    .font(.custom(SappyDesign.fontFamily, size: 16))
                    .foregroundColor(.black.opacity(SappyDesign.textTertiaryOpacity))
            }
            .offset(y: showFeedbackText ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.3), value: showFeedbackText)

            Spacer().frame(height: 10)

            // Change answer button
            Button(action: resetMood) {
                Text("Change my answer")
                    .font(.custom(SappyDesign.fontFamily, size: 14))
                    .kerning(1.0)
                    .foregroundColor(.black.opacity(SappyDesign.textTertiaryOpacity))
                    .underline()
                    .padding()
            }
            .offset(y: showFeedbackText ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.5), value: showFeedbackText)
        }
    }
}

#Preview {
    ContentView()
}
