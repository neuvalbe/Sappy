//
//  AuthHelper.swift
//  Sappy
//
//  Created by Neuval Studio on 26/03/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Shared Auth Completion

/// Centralized post-authentication logic shared by all sign-in methods.
///
/// Both `LoginView` (Sign In with Apple) and `SappyAuthView` (email/password)
/// call this after successful Firebase authentication. Extracting it here
/// eliminates code duplication and ensures consistent behavior:
///
/// 1. Fires success haptic
/// 2. Sets `hasCompletedFirstSignUp` so returning users skip country picker
/// 3. Persists the user's country to `users/{uid}` (cross-device sync)
/// 4. Transitions app state to `.tracking`
enum AuthHelper {

    /// Shared success path for all authentication methods.
    ///
    /// - Parameters:
    ///   - appState: Binding to the app's root navigation state.
    ///   - dismiss: Optional dismiss action (for sheet-presented auth views like `SappyAuthView`).
    static func completeAuthentication(
        appState: Binding<AppState>,
        dismiss: DismissAction? = nil
    ) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UserDefaults.standard.set(true, forKey: "hasCompletedFirstSignUp")

        // Persist country to Firestore so it follows the account across devices
        if let uid = Auth.auth().currentUser?.uid {
            let country = UserDefaults.standard.string(forKey: "userCountry") ?? ""
            if !country.isEmpty {
                Firestore.firestore().collection("users").document(uid).setData([
                    "country": country,
                    "mood": "",
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true) { error in
                    if let error {
                        print("[Sappy] Auth country persist failed: \(error.localizedDescription)")
                    }
                }
            }
        }

        if let dismiss {
            dismiss()
            // Delay transition to allow sheet dismissal animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appState.wrappedValue = .tracking
                }
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appState.wrappedValue = .tracking
            }
        }
    }
}
