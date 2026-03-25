//
//  SappyLegalView.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI

// MARK: - Legal View

/// A scrollable sheet presenting Sappy's Terms of Service and Privacy Policy.
///
/// Presented modally from `LoginView` when the user taps the legal disclaimer.
/// Uses `LegalSection` and `LegalParagraph` helper components for consistent formatting.
struct SappyLegalView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 32) {

                        // MARK: Terms of Service

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms of Service")
                                .font(.custom(SappyDesign.fontFamily, size: 24))
                                .foregroundColor(SappyDesign.textPrimary)

                            Text("Last Updated: March 2026")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.black.opacity(SappyDesign.textSecondaryOpacity))

                            LegalParagraph("Welcome to Sappy. By accessing or using our application, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use Sappy.")

                            LegalSection(title: "1. Use of the App", text: "Sappy is a digital mood-tracking application. You agree to use the app only for your personal, non-commercial use. You must be at least 13 years old to use this service.")

                            LegalSection(title: "2. User Accounts", text: "When you create an account, you must provide accurate information. You are solely responsible for safeguarding your password and for all activities that occur under your account.")

                            LegalSection(title: "3. User Data & Content", text: "All mood data you log belongs to you. We do not claim ownership of your emotional states. However, you grant us a license to securely store and process this data to provide the service.")

                            LegalSection(title: "4. Disclaimers", text: "Sappy is not a medical device. It does not provide medical advice, diagnosis, or treatment. If you are experiencing a mental health crisis, please contact professional medical services or emergency responders immediately.")
                        }

                        Divider()
                            .padding(.vertical, 16)

                        // MARK: Privacy Policy

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Privacy Policy")
                                .font(.custom(SappyDesign.fontFamily, size: 24))
                                .foregroundColor(SappyDesign.textPrimary)

                            LegalParagraph("Your privacy is immensely important to us. Because we deal with your emotions, we handle your data with the highest level of care and security.")

                            LegalSection(title: "1. Information We Collect", text: "We collect the information you provide directly to us (such as your name and email address when creating an account) and the mood states ('happy' or 'sad') that you log within the app.")

                            LegalSection(title: "2. How We Use Information", text: "We use the information we collect strictly to provide, maintain, and improve the Sappy application. We do not sell your personal data or emotional logs to any third-party advertisers.")

                            LegalSection(title: "3. Data Security", text: "We implement robust structural security measures to protect your data from unauthorized access, alteration, disclosure, or destruction. However, no internet transmission is entirely secure.")

                            LegalSection(title: "4. Your Rights", text: "You have the right to access, update, or delete your information at any time. You may request the total deletion of your account and all associated mood history by contacting our support team.")
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
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
}

// MARK: - Legal Helper Components

/// A titled paragraph block used in the legal document layout.
struct LegalSection: View {
    var title: String
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom(SappyDesign.fontFamily, size: 16))
                .foregroundColor(SappyDesign.textPrimary)

            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color.black.opacity(0.7))
                .lineSpacing(4)
        }
    }
}

/// A standalone legal body paragraph with consistent styling.
struct LegalParagraph: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundColor(Color.black.opacity(0.7))
            .lineSpacing(4)
    }
}

#Preview {
    SappyLegalView()
}
