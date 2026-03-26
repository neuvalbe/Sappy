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
/// Global mood counts and per-country breakdowns are synced in real-time
/// via `TrackingViewModel`, which holds a Firestore snapshot listener.
///
/// ## Vote Persistence
/// The user's vote is persisted across sessions. "Change my answer" returns
/// to the selection UI but keeps the active vote in Firestore until a new
/// mood is chosen.
struct TrackingView: View {

    // MARK: - State & Data

    @Binding var appState: AppState
    @State private var selectedMood: Mood? = nil

    /// Live real-time global counts and logic synced via Firestore.
    @StateObject private var viewModel = TrackingViewModel()

    /// Controls the settings sheet presentation.
    @State private var showSettings = false

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
            GeometryReader { geo in
                let totalHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                ZStack {
                    Color.white
                    Color.black
                        .offset(y: selectedMood == .happy ? 0 : (selectedMood == .sad ? -totalHeight : -totalHeight / 2))
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: selectedMood)

            // MARK: Invisible Touch Targets

            if selectedMood == nil && splitOffset > 100 {
                VStack(spacing: 0) {
                    Color.white.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { selectMood(.happy) }
                        .accessibilityLabel("I feel happy")

                    Color.white.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { selectMood(.sad) }
                        .accessibilityLabel("I feel sad")
                }
            }

            // MARK: Top Face — Happy :)

            VStack(spacing: 24) {
                SappyLogoShape(drawLeft: false, drawColon: true, drawRight: true)
                    .trim(from: 0, to: entryTrim)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: SappyDesign.trackingStrokeWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: SappyDesign.trackingFaceSize, height: SappyDesign.trackingFaceSize)
                    .scaleEffect(selectedMood == .happy ? SappyDesign.selectedFaceScale : 1.0)

                Text("happy.")
                    .font(.custom(SappyDesign.fontFamily, size: 48))
                    .fontWeight(.light)
                    .italic()
                    .kerning(1.5)
                    .foregroundColor(.white)
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
                        Color.black,
                        style: StrokeStyle(lineWidth: SappyDesign.trackingStrokeWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: SappyDesign.trackingFaceSize, height: SappyDesign.trackingFaceSize)
                    .scaleEffect(selectedMood == .sad ? SappyDesign.selectedFaceScale : 1.0)

                Text("sad.")
                    .font(.custom(SappyDesign.fontFamily, size: 48))
                    .fontWeight(.light)
                    .italic()
                    .kerning(1.5)
                    .foregroundColor(.black)
                    .opacity(selectedMood == nil ? textOpacity : 0)
            }
            .scaleEffect(selectedMood == nil ? (2.0 - breathingScale) : 1.0)
            .offset(y: selectedMood == .sad
                    ? SappyDesign.selectedFaceOffset
                    : (selectedMood == .happy ? SappyDesign.dismissedFaceOffset : splitOffset - breathingOffset))
            .opacity(selectedMood == .happy ? 0 : 1)
            .zIndex(selectedMood == .sad ? 10 : 1)


            // MARK: Feedback Content

            if let mode = selectedMood {
                feedbackContent(for: mode)
                    .offset(y: SappyDesign.feedbackContentOffset)
                    .opacity(showFeedbackText ? 1 : 0)
            }
        }
        // MARK: Settings Gear Overlay
        .overlay(alignment: .topTrailing) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedMood == .sad ? .black.opacity(0.35) : .white.opacity(0.35))
                    .padding(20)
            }
            .accessibilityLabel("Settings")
            .opacity(splitOffset > 100 ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: splitOffset > 100)
        }
        .sheet(isPresented: $showSettings) {
            SappySettingsView(appState: $appState, viewModel: viewModel)
        }
        .preferredColorScheme(selectedMood == .sad ? .light : .dark)
        .onAppear {
            viewModel.startSync()
            // Restore persisted mood state from previous session
            if let persisted = viewModel.currentMood {
                selectedMood = persisted
                showFeedbackText = true
                // Skip entrance animation — go directly to feedback state
                entryTrim = 1.0
                splitOffset = SappyDesign.splitDistance
                textOpacity = 1.0
            } else {
                launchCinematicEntrance()
            }
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
        
        // ViewModel handles atomic swap: if same mood → no-op,
        // if different mood → batch decrement old + increment new.
        viewModel.vote(mood: mood)

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            selectedMood = mood
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                showFeedbackText = true
            }
        }
    }

    /// Returns to the selection UI but **keeps the existing vote** active
    /// in Firestore. The vote is only changed when the user picks a new mood.
    private func resetMood() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Do NOT subtract vote — it remains active until a new mood is selected.

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
        VStack(spacing: 40) {

            // Real-time counter (live) - guaranteed to be at least 1 since they just voted
            let count = max(1, mode == .happy ? viewModel.globalHappyCount : viewModel.globalSadCount)

            VStack(spacing: 8) {
                Text("\(count.formatted()) \(count == 1 ? "person" : "people")")
                    .font(.custom(SappyDesign.fontFamily, size: 24))
                    .foregroundColor(mode == .happy ? .white : .black.opacity(0.85))

                Text("\(count == 1 ? "feels" : "feel") \(mode.rawValue) right now")
                    .font(.custom(SappyDesign.fontFamily, size: 16))
                    .foregroundColor(mode == .happy ? .white.opacity(0.7) : .black.opacity(SappyDesign.textTertiaryOpacity))
            }
            .offset(y: showFeedbackText ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.1), value: showFeedbackText)

            // Country Breakdown Tracker
            let countryStats: [(String, Int)] = mode == .happy
                ? viewModel.happyCountryStats
                : viewModel.sadCountryStats

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    Spacer().frame(width: 8)
                    ForEach(0..<countryStats.count, id: \.self) { i in
                        let code = countryStats[i].0
                        let count = countryStats[i].1
                        HStack(spacing: 6) {
                            Text(code.uppercased())
                                .font(.custom(SappyDesign.fontFamily, size: 11))
                                .fontWeight(.semibold)
                                .kerning(1.0)
                                .foregroundColor(mode == .happy ? .white : .black.opacity(0.7))
                            Text("\(count)")
                                .font(.custom(SappyDesign.fontFamily, size: 11))
                                .foregroundColor(mode == .happy ? .white.opacity(0.5) : .black.opacity(0.4))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(mode == .happy ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                        )
                    }
                    Spacer().frame(width: 8)
                }
            }
            .frame(height: 40)
            .offset(y: showFeedbackText ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: showFeedbackText)

            // Change answer button
            Button(action: resetMood) {
                Text("Change my answer")
                    .font(.custom(SappyDesign.fontFamily, size: 14))
                    .kerning(1.0)
                    .foregroundColor(mode == .happy ? .white.opacity(0.7) : .black.opacity(SappyDesign.textTertiaryOpacity))
                    .underline()
                    .padding()
            }
            .offset(y: showFeedbackText ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.3), value: showFeedbackText)
        }
    }
}

#Preview {
    ContentView()
}
