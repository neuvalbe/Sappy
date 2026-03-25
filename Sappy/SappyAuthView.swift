//
//  SappyAuthView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI

// MARK: - Sappy Email/Password Auth Sheet

/// A modal authentication sheet for Sappy's native email/password flow.
///
/// Supports both sign-up (with name field) and sign-in modes, toggled inline.
/// Presented as a `.sheet` from `LoginView`. On success, dismisses itself
/// and transitions the app to `.tracking` state after a brief delay.
///
/// **Backend**: Currently front-end only. `handleAuthSuccess()` sets
/// `hasCompletedFirstSignUp` in `@AppStorage` and routes to the tracking view.
/// Firebase Authentication integration is the planned next step.
struct SappyAuthView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var appState: AppState
    @AppStorage("hasCompletedFirstSignUp") private var hasCompletedFirstSignUp: Bool = false

    // MARK: - State

    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 24) {
                    // MARK: Header

                    VStack(spacing: 8) {
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.custom(SappyDesign.fontFamily, size: 28))
                            .foregroundColor(SappyDesign.textPrimary)

                        Text(isSignUp ? "Join the Sappy community." : "Sign in to continue feeling.")
                            .font(.custom(SappyDesign.fontFamily, size: 14))
                            .foregroundColor(Color.black.opacity(SappyDesign.textSecondaryOpacity))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // MARK: Form Fields

                    VStack(spacing: 16) {
                        if isSignUp {
                            SappyTextField(placeholder: "Full Name", text: $name, keyboardType: .default, textContentType: .name)
                        }

                        SappyTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                            .textInputAutocapitalization(.never)

                        SappyTextField(placeholder: "Password", text: $password, keyboardType: .default, textContentType: isSignUp ? .newPassword : .password, isSecure: true)
                    }

                    // MARK: Submit Button

                    Button(action: {
                        handleAuthSuccess()
                    }) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.custom(SappyDesign.fontFamily, size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: SappyDesign.buttonHeight)
                            .background(isFormValid ? Color.black : Color.black.opacity(SappyDesign.disabledOpacity))
                            .cornerRadius(SappyDesign.cornerRadius)
                    }
                    .buttonStyle(SquishableButtonStyle())
                    .disabled(!isFormValid)
                    .padding(.top, 8)

                    // MARK: Toggle Sign In / Sign Up

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSignUp.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(Color.black.opacity(SappyDesign.textSecondaryOpacity))

                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(SappyDesign.textPrimary)
                                .fontWeight(.semibold)
                        }
                        .font(.custom(SappyDesign.fontFamily, size: 13))
                    }
                    .padding(.top, 16)

                    Spacer()
                }
                .padding(.horizontal, SappyDesign.horizontalPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SappyDesign.textPrimary)
                            .padding(8)
                            .background(Color.black.opacity(SappyDesign.inputBackgroundOpacity))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Validation

    /// Returns `true` when all required fields are non-empty and password ≥ 6 chars.
    private var isFormValid: Bool {
        if isSignUp {
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && !email.trimmingCharacters(in: .whitespaces).isEmpty
                && password.count >= 6
        } else {
            return !email.trimmingCharacters(in: .whitespaces).isEmpty
                && password.count >= 6
        }
    }

    // MARK: - Auth Handler

    /// Finalizes the authentication attempt.
    ///
    /// Currently a front-end stub: fires a success haptic, persists the
    /// sign-up flag, dismisses the sheet, and routes to `.tracking`.
    /// Will be replaced with Firebase Auth calls during backend integration.
    private func handleAuthSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        hasCompletedFirstSignUp = true
        dismiss()

        // Brief delay allows the sheet dismiss animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appState = .tracking
            }
        }
    }
}

// MARK: - Sappy Text Field

/// A branded text/secure field matching Sappy's input design language.
///
/// Renders with a light fill background, subtle border, and the brand typeface.
/// Supports both plain `TextField` and `SecureField` via the `isSecure` flag.
struct SappyTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.custom(SappyDesign.fontFamily, size: 16))
        .textContentType(textContentType)
        .keyboardType(keyboardType)
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
}
