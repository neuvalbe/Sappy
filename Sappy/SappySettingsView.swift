//
//  SappySettingsView.swift
//  Sappy
//
//  Created by Neuval Studio on 26/03/2026.
//

import SwiftUI
import FirebaseAuth

// MARK: - Settings View

/// A minimal branded settings sheet for account management.
///
/// Provides sign-out and account deletion (required by App Store Guideline 5.1.1(v)).
/// Matches the Sappy design language with Dela Gothic One typography.
struct SappySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var appState: AppState
    @ObservedObject var viewModel: TrackingViewModel
    
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: User Info
                    
                    VStack(spacing: 12) {
                        // Avatar circle
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.06))
                                .frame(width: 72, height: 72)
                            
                            Text(userInitial)
                                .font(.custom(SappyDesign.fontFamily, size: 28))
                                .foregroundColor(SappyDesign.textPrimary)
                        }
                        
                        Text(displayName)
                            .font(.custom(SappyDesign.fontFamily, size: 18))
                            .foregroundColor(SappyDesign.textPrimary)
                        
                        Text(displayEmail)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(Color.black.opacity(SappyDesign.textSecondaryOpacity))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                    
                    // MARK: Current Vote
                    
                    if let mood = viewModel.currentMood {
                        HStack {
                            Text("Current mood")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.black.opacity(SappyDesign.textSecondaryOpacity))
                            Spacer()
                            if mood == .happy {
                                Image(systemName: "face.smiling")
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.black)
                                    .clipShape(Circle())
                                Text("Happy")
                                    .foregroundColor(SappyDesign.textPrimary)
                            } else {
                                Image(systemName: "face.dashed")
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.black)
                                    .clipShape(Circle())
                                Text("Sad")
                                    .foregroundColor(SappyDesign.textPrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.03))
                        )
                        .padding(.horizontal, SappyDesign.horizontalPadding)
                        .padding(.bottom, 16)
                    }
                    
                    // MARK: Error
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, SappyDesign.horizontalPadding)
                            .padding(.bottom, 16)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // MARK: Actions
                    
                    VStack(spacing: 12) {
                        // Sign Out
                        Button(action: performSignOut) {
                            Text("Sign Out")
                                .font(.custom(SappyDesign.fontFamily, size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(SappyDesign.textPrimary)
                                .frame(maxWidth: .infinity)
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
                        .accessibilityLabel("Sign out of your account")
                        
                        // Delete Account
                        Button(action: { showDeleteConfirmation = true }) {
                            ZStack {
                                Text("Delete Account")
                                    .font(.custom(SappyDesign.fontFamily, size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .opacity(isDeleting ? 0 : 1)
                                
                                if isDeleting {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: SappyDesign.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: SappyDesign.cornerRadius, style: .continuous)
                                    .fill(Color.red.opacity(0.85))
                            )
                        }
                        .buttonStyle(SquishableButtonStyle())
                        .disabled(isDeleting)
                        .accessibilityLabel("Delete your account permanently")
                    }
                    .padding(.horizontal, SappyDesign.horizontalPadding)
                    .padding(.bottom, SappyDesign.bottomPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SappyDesign.textPrimary)
                            .padding(8)
                            .background(Color.black.opacity(SappyDesign.inputBackgroundOpacity))
                            .clipShape(Circle())
                    }
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Permanently", role: .destructive) {
                    performDeleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all associated data. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var userInitial: String {
        if let name = Auth.auth().currentUser?.displayName, !name.isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        if let email = Auth.auth().currentUser?.email, !email.isEmpty {
            return String(email.prefix(1)).uppercased()
        }
        return "?"
    }
    
    private var displayName: String {
        Auth.auth().currentUser?.displayName ?? "Sappy User"
    }
    
    private var displayEmail: String {
        if let email = Auth.auth().currentUser?.email, !email.isEmpty {
            return email
        }
        // SIWA users may not have an email — detect via provider ID
        let providers = Auth.auth().currentUser?.providerData.map(\.providerID) ?? []
        if providers.contains("apple.com") {
            return "Signed in with Apple"
        }
        return "Signed in"
    }
    
    // MARK: - Actions
    
    private func performSignOut() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.signOut()
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appState = .login
            }
        }
    }
    
    private func performDeleteAccount() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        isDeleting = true
        errorMessage = nil
        
        viewModel.deleteAccount { error in
            isDeleting = false
            if let error = error {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                errorMessage = error
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        appState = .login
                    }
                }
            }
        }
    }
}
