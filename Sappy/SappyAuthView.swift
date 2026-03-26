//
//  SappyAuthView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import FirebaseAuth


// MARK: - Sappy Email/Password Auth Sheet

/// A modal authentication sheet for Sappy's native email/password flow.
///
/// Supports both sign-up (with name field) and sign-in modes, toggled inline.
/// Presented as a `.sheet` from `LoginView`. On success, dismisses itself
/// and transitions the app to `.tracking` state.
///
/// **Backend**: Connected to Firebase Email/Password Authentication.
struct SappyAuthView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var appState: AppState


    // MARK: - State

    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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

                    // MARK: Error Message

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.custom(SappyDesign.fontFamily, size: 13))
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .offset(y: -5)))
                    }

                    // MARK: Submit Button

                    Button(action: {
                        handleAuth()
                    }) {
                        ZStack {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.custom(SappyDesign.fontFamily, size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(isLoading ? 0 : 1)

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: SappyDesign.buttonHeight)
                        .background(isFormValid && !isLoading ? Color.black : Color.black.opacity(SappyDesign.disabledOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous))
                    }
                    .buttonStyle(SquishableButtonStyle())
                    .disabled(!isFormValid || isLoading)
                    .padding(.top, 8)

                    // MARK: Toggle Sign In / Sign Up

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSignUp.toggle()
                            errorMessage = nil
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

    // MARK: - Firebase Auth Handler

    /// Routes to the correct Firebase auth method (sign-up or sign-in).
    private func handleAuth() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        errorMessage = nil
        isLoading = true

        if isSignUp {
            Auth.auth().createUser(withEmail: email.trimmingCharacters(in: .whitespaces), password: password) { authResult, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        errorMessage = Self.friendlyError(error)
                        return
                    }
                    
                    // Update display name if provided
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        let changeRequest = authResult?.user.createProfileChangeRequest()
                        changeRequest?.displayName = name.trimmingCharacters(in: .whitespaces)
                        changeRequest?.commitChanges(completion: nil)
                    }
                    
                    completeAuthentication()
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email.trimmingCharacters(in: .whitespaces), password: password) { _, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        errorMessage = Self.friendlyError(error)
                        return
                    }
                    completeAuthentication()
                }
            }
        }
    }

    /// Shared success path for both sign-up and sign-in.
    private func completeAuthentication() {
        AuthHelper.completeAuthentication(appState: $appState, dismiss: dismiss)
    }

    /// Maps Firebase error codes to user-friendly messages.
    private static func friendlyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered. Try signing in."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password must be at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return "Incorrect email or password."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found. Try signing up."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Sappy Text Field

/// A branded text/secure field matching Sappy's input design language.
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
