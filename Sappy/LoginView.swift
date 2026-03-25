//
//  LoginView.swift
//  Sappy
//

import SwiftUI
import AuthenticationServices

enum AuthStep {
    case countrySelection
    case signinOptions
}

struct LoginView: View {
    @Binding var appState: AppState
    
    // Persistent state: skips country picker if the user is returning
    @AppStorage("hasCompletedFirstSignUp") private var hasCompletedFirstSignUp: Bool = false
    
    @State private var authStep: AuthStep = .countrySelection
    @State private var selectedCountry: String = "Select Country"
    @State private var strokeEnd: CGFloat = 0.0
    @State private var showElements = false
    
    let countries = [
        "United States", "United Kingdom", "Canada", "Australia",
        "Germany", "France", "Japan", "South Korea", "Brazil", "India"
    ]
    
    var body: some View {
        ZStack {
            // Pure White background
            Color.white.ignoresSafeArea()
            

            
            VStack {
                Spacer()
                
                // Deep Black Vector Logo preserving beautiful drawing effect
                SappyLogoShape()
                    .trim(from: 0.0, to: strokeEnd)
                    .stroke(
                        Color(white: 0.1),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 80, height: 80)
                
                if showElements {
                    VStack(spacing: 8) {
                        Text("sappy")
                            .font(.custom("DelaGothicOne-Regular", size: 32))
                            .fontWeight(.bold)
                            .kerning(4)
                            .foregroundColor(Color(white: 0.1))
                        
                        Text("Are you happy or sad?")
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(Color.black.opacity(0.5))
                            .padding(.bottom, 8)
                    }
                    .padding(.top, 40)
                    .transition(.opacity.combined(with: .offset(y: 20)))
                }
                
                Spacer()
                
                if showElements {
                    VStack(spacing: 20) {
                        if authStep == .countrySelection {
                            // --- STEP 1: Country Picker ---
                            Text("Where are you joining from?")
                                .foregroundColor(Color.black.opacity(0.8))
                                .font(.custom("DelaGothicOne-Regular", size: 18))
                                .fontWeight(.semibold)
                                .padding(.bottom, 8)
                            
                            Menu {
                                ForEach(countries, id: \.self) { country in
                                    Button(country) {
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                        selectedCountry = country
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCountry)
                                        .foregroundColor(selectedCountry == "Select Country" ? .black.opacity(0.4) : .black)
                                        .font(.custom("DelaGothicOne-Regular", size: 16))
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundColor(.black.opacity(0.3))
                                        .font(.custom("DelaGothicOne-Regular", size: 12))
                                        .fontWeight(.bold)
                                }
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
                            .buttonStyle(SquishableButtonStyle())
                            
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    authStep = .signinOptions
                                }
                            }) {
                                Text("Continue")
                                    .font(.custom("DelaGothicOne-Regular", size: 16))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(selectedCountry == "Select Country" ? Color.black.opacity(0.2) : Color.black)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(SquishableButtonStyle())
                            .disabled(selectedCountry == "Select Country")
                            .padding(.top, 8)
                            
                        } else {
                            // --- STEP 2: Auth Options ---
                            
                            // Custom Sappy Auth Button
                            Button(action: {
                                handleAuthentication()
                            }) {
                                HStack(spacing: 12) {
                                    SappyLogoShape()
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                                        .frame(width: 14, height: 18)
                                    
                                    Text(hasCompletedFirstSignUp ? "Sign In to Sappy" : "Continue with Sappy")
                                        .font(.custom("DelaGothicOne-Regular", size: 17))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(white: 0.1))
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
                                    case .success(_):
                                        handleAuthentication()
                                    case .failure(let error):
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.error)
                                        print("Auth failed: \(error.localizedDescription)")
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.whiteOutline)
                            .frame(height: 56)
                            .cornerRadius(16)
                        }
                        
                        // Disclaimer
                        Text("By continuing, you agree to Sappy's Terms & Conditions and Privacy Policy.")
                            .font(.custom("DelaGothicOne-Regular", size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                    .transition(.opacity.combined(with: .offset(y: 20)))
                }
            }
        }
        .onAppear {
            if hasCompletedFirstSignUp {
                authStep = .signinOptions
            } else {
                authStep = .countrySelection
            }
            
            withAnimation(.easeOut(duration: 1.5)) {
                strokeEnd = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showElements = true
                }
            }
        }
    }
    
    private func handleAuthentication() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        hasCompletedFirstSignUp = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appState = .tracking
        }
    }
}

// MARK: - Squishable Button Style (Tactile scaling)
struct SquishableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    LoginView(appState: .constant(.login))
}
