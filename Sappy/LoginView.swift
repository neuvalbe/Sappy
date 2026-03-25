//
//  LoginView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import AuthenticationServices

// MARK: - Auth Step

/// The two-step authentication flow within the login screen.
enum AuthStep {
    /// First-time users select their country before proceeding.
    case countrySelection
    /// Users choose between Sappy email auth or Sign In with Apple.
    case signinOptions
}

// MARK: - Login View

/// The authentication screen for Sappy.
///
/// Presents a two-step flow: first-time users pick a country, then all users
/// choose between native Sappy email/password auth or Sign In with Apple.
/// Returning users (detected via `@AppStorage`) skip the country step.
///
/// The logo draws on with a `.trim()` animation, followed by the "sappy" text
/// revealing left-to-right via a mask scale.
struct LoginView: View {
    @Binding var appState: AppState

    /// Persists whether the user has completed sign-up at least once.
    /// When `true`, the country picker is skipped on subsequent launches.
    @AppStorage("hasCompletedFirstSignUp") private var hasCompletedFirstSignUp: Bool = false

    // MARK: - State

    @State private var authStep: AuthStep = .countrySelection
    @State private var selectedCountry: String = "Select Country"
    @State private var drawProgress: CGFloat = 0.0
    @State private var showElements = false
    @State private var showSappyAuth = false
    @State private var showLegal = false

    /// Available countries for the country picker.
    /// Will be expanded or sourced from a backend during Firebase integration.
    let countries = [
        "United States", "United Kingdom", "Canada", "Australia",
        "Germany", "France", "Japan", "South Korea", "Brazil", "India"
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                Spacer()

                // MARK: Logo + Title

                SappyLogoShape()
                    .trim(from: 0.0, to: drawProgress)
                    .stroke(
                        SappyDesign.textPrimary,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 80, height: 80)

                // "sappy" text with left-to-right reveal mask synced to logo draw
                Text("sappy")
                    .font(.custom(SappyDesign.fontFamily, size: 32))
                    .fontWeight(.bold)
                    .kerning(4)
                    .foregroundColor(SappyDesign.textPrimary)
                    .padding(.top, 40)
                    .mask(
                        Rectangle()
                            .scaleEffect(x: drawProgress, y: 1.0, anchor: .leading)
                    )

                if showElements {
                    VStack(spacing: 8) {
                        Text("No app asks you how you feel.")
                            .font(.custom(SappyDesign.fontFamily, size: 14))
                            .foregroundColor(Color.black.opacity(SappyDesign.textSecondaryOpacity))
                            .padding(.bottom, 8)
                    }
                    .transition(.opacity.combined(with: .offset(y: 20)))
                }

                Spacer()

                // MARK: Auth Flow

                if showElements {
                    VStack(spacing: 20) {
                        if authStep == .countrySelection {
                            countrySelectionStep
                        } else {
                            signinOptionsStep
                        }

                        // Legal disclaimer
                        Button(action: {
                            showLegal = true
                        }) {
                            Text("By continuing, you agree to Sappy's **Terms & Conditions** and **Privacy Policy**.")
                                .font(.custom(SappyDesign.fontFamily, size: 11))
                                .foregroundColor(Color.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, SappyDesign.horizontalPadding)
                    .padding(.bottom, SappyDesign.bottomPadding)
                    .transition(.opacity.combined(with: .offset(y: 20)))
                }
            }
        }
        .sheet(isPresented: $showSappyAuth) {
            SappyAuthView(appState: $appState)
        }
        .sheet(isPresented: $showLegal) {
            SappyLegalView()
        }
        .onAppear {
            if hasCompletedFirstSignUp {
                authStep = .signinOptions
            } else {
                authStep = .countrySelection
            }

            withAnimation(.easeOut(duration: 1.5)) {
                drawProgress = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showElements = true
                }
            }
        }
    }

    // MARK: - Step 1: Country Selection

    /// Country picker + Continue button for first-time users.
    private var countrySelectionStep: some View {
        VStack(spacing: 20) {
            Text("Where are you joining from?")
                .foregroundColor(Color.black.opacity(0.8))
                .font(.custom(SappyDesign.fontFamily, size: 18))
                .fontWeight(.semibold)
                .padding(.bottom, 8)

            Menu {
                ForEach(countries, id: \.self) { country in
                    Button(country) {
                        UISelectionFeedbackGenerator().selectionChanged()
                        selectedCountry = country
                    }
                }
            } label: {
                HStack {
                    Text(selectedCountry)
                        .foregroundColor(selectedCountry == "Select Country" ? .black.opacity(SappyDesign.textTertiaryOpacity) : .black)
                        .font(.custom(SappyDesign.fontFamily, size: 16))
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.black.opacity(SappyDesign.textQuaternaryOpacity))
                        .font(.custom(SappyDesign.fontFamily, size: 12))
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 20)
                .frame(height: SappyDesign.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(SappyDesign.inputBackgroundOpacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(SappyDesign.inputBorderOpacity), lineWidth: 1)
                )
            }
            .buttonStyle(SquishableButtonStyle())

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    authStep = .signinOptions
                }
            }) {
                Text("Continue")
                    .font(.custom(SappyDesign.fontFamily, size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: SappyDesign.buttonHeight)
                    .background(selectedCountry == "Select Country" ? Color.black.opacity(SappyDesign.disabledOpacity) : Color.black)
                    .cornerRadius(SappyDesign.cornerRadius)
            }
            .buttonStyle(SquishableButtonStyle())
            .disabled(selectedCountry == "Select Country")
            .padding(.top, 8)
        }
    }

    // MARK: - Step 2: Sign-In Options

    /// Sappy email auth button + Sign In with Apple button for all users.
    private var signinOptionsStep: some View {
        VStack(spacing: 20) {
            // Custom Sappy Auth Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showSappyAuth = true
            }) {
                HStack(spacing: 12) {
                    SappyLogoShape()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: 14, height: 18)

                    Text(hasCompletedFirstSignUp ? "Sign In to Sappy" : "Continue with Sappy")
                        .font(.custom(SappyDesign.fontFamily, size: 17))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: SappyDesign.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous)
                        .fill(SappyDesign.textPrimary)
                )
            }
            .buttonStyle(SquishableButtonStyle())

            // Native Apple Sign In
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success:
                        handleAuthentication()
                    case .failure(let error):
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        print("[Sappy] Auth failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: SappyDesign.buttonHeight)
            .cornerRadius(SappyDesign.cornerRadius)
        }
    }

    // MARK: - Auth Handler

    /// Handles a successful authentication from Sign In with Apple.
    ///
    /// Fires a success haptic, persists the first-sign-up flag, and
    /// transitions to the tracking view with a spring animation.
    private func handleAuthentication() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        hasCompletedFirstSignUp = true

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appState = .tracking
        }
    }
}

#Preview {
    LoginView(appState: .constant(.login))
}
