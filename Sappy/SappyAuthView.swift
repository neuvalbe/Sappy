//
//  SappyAuthView.swift
//  Sappy
//

import SwiftUI

struct SappyAuthView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var appState: AppState
    @AppStorage("hasCompletedFirstSignUp") private var hasCompletedFirstSignUp: Bool = false
    
    @State private var isSignUp = false
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header text
                    VStack(spacing: 8) {
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.custom("DelaGothicOne-Regular", size: 28))
                            .foregroundColor(Color(white: 0.1))
                        
                        Text(isSignUp ? "Join the Sappy community." : "Sign in to continue feeling.")
                            .font(.custom("DelaGothicOne-Regular", size: 14))
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            SappyTextField(placeholder: "Full Name", text: $name, keyboardType: .default, textContentType: .name)
                        }
                        
                        SappyTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                            .autocapitalization(.none)
                        
                        SappyTextField(placeholder: "Password", text: $password, keyboardType: .default, textContentType: isSignUp ? .newPassword : .password, isSecure: true)
                    }
                    
                    // Submit Button
                    Button(action: {
                        handleAuthSuccess()
                    }) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isFormValid ? Color.black : Color.black.opacity(0.2))
                            .cornerRadius(16)
                    }
                    .buttonStyle(SquishableButtonStyle())
                    .disabled(!isFormValid)
                    .padding(.top, 8)
                    
                    // Toggle Mode
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSignUp.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(Color.black.opacity(0.5))
                            
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(Color(white: 0.1))
                                .fontWeight(.semibold)
                        }
                        .font(.custom("DelaGothicOne-Regular", size: 13))
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(white: 0.1))
                            .padding(8)
                            .background(Color.black.opacity(0.04))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !name.trimmingCharacters(in: .whitespaces).isEmpty && !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
        } else {
            return !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
        }
    }
    
    private func handleAuthSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        hasCompletedFirstSignUp = true
        dismiss()
        
        // Slight delay to let the sheet dismiss before routing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appState = .tracking
            }
        }
    }
}

// Custom specialized text/secure field matching Sappy's design language
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
        .font(.custom("DelaGothicOne-Regular", size: 16))
        .textContentType(textContentType)
        .keyboardType(keyboardType)
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}
