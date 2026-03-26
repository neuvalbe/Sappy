//
//  LoginView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

import CryptoKit

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
/// **Sign In with Apple** is wired directly to Firebase Auth via
/// `OAuthProvider.appleCredential`, ensuring a real Firebase user identity.
struct LoginView: View {
    @Binding var appState: AppState

    /// Persists whether the user has completed sign-up at least once.
    /// When `true`, the country picker is skipped on subsequent launches.
    @AppStorage("hasCompletedFirstSignUp") private var hasCompletedFirstSignUp: Bool = false

    // MARK: - State

    @State private var authStep: AuthStep = .countrySelection
    @State private var selectedCountryName: String = "Select Country"
    @State private var selectedCountryCode: String = ""
    @AppStorage("userCountry") private var persistedCountry: String = ""
    @State private var drawProgress: CGFloat = 0.0
    @State private var showElements = false
    @State private var showSappyAuth = false
    @State private var showLegal = false
    @State private var authError: String?

    /// Nonce used for Sign In with Apple → Firebase credential exchange.
    @State private var currentNonce: String?

    /// All countries from ISO 3166-1 alpha-2, sorted by display name.
    /// The code is stored in `@AppStorage` and used as the Firestore key.
    static let countries: [(name: String, code: String)] = {
        let locale = Locale.current
        return Locale.Region.isoRegions
            .map { region in
                let code = region.identifier
                let name = locale.localizedString(forRegionCode: code) ?? code
                return (name: name, code: code)
            }
            .filter { !$0.name.isEmpty && $0.code.count == 2 }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

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

                        // Auth error message
                        if let authError = authError {
                            Text(authError)
                                .font(.custom(SappyDesign.fontFamily, size: 13))
                                .foregroundColor(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
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
                ForEach(Self.countries, id: \.code) { country in
                    Button(country.name) {
                        UISelectionFeedbackGenerator().selectionChanged()
                        selectedCountryName = country.name
                        selectedCountryCode = country.code
                    }
                }
            } label: {
                HStack {
                    Text(selectedCountryName)
                        .foregroundColor(selectedCountryCode.isEmpty ? .black.opacity(SappyDesign.textTertiaryOpacity) : .black)
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
                persistedCountry = selectedCountryCode
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
                    .background(selectedCountryCode.isEmpty ? Color.black.opacity(SappyDesign.disabledOpacity) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous))
            }
            .buttonStyle(SquishableButtonStyle())
            .disabled(selectedCountryCode.isEmpty)
            .accessibilityLabel("Continue to sign in")
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

            // Native Apple Sign In — wired to Firebase via OAuthProvider credential
            SignInWithAppleButton(
                onRequest: { request in
                    let nonce = Self.randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = Self.sha256(nonce)
                },
                onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: SappyDesign.buttonHeight)
            .clipShape(RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous))
        }
    }

    // MARK: - Sign In with Apple → Firebase

    /// Extracts the Apple credential and exchanges it for a Firebase user identity.
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = currentNonce else {
                authError = "Failed to retrieve Apple credential."
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        authError = error.localizedDescription
                        return
                    }
                    completeAuthentication()
                }
            }

        case .failure(let error):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            authError = error.localizedDescription
        }
    }

    /// Shared success path for all auth methods.
    private func completeAuthentication() {
        authError = nil
        AuthHelper.completeAuthentication(appState: $appState)
    }

    // MARK: - Crypto Helpers (SIWA Nonce)

    /// Generates a cryptographically secure random nonce string.
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("[Sappy] SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// Returns the SHA256 hash of the input string, hex-encoded.
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    LoginView(appState: .constant(.login))
}
