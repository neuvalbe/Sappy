//
//  TrackingView.swift
//  Sappy
//

import SwiftUI

// MARK: - Mood Selection
enum Mood {
    case happy
    case sad
}

struct TrackingView: View {
    @State private var showText = false
    @State private var selectedMood: Mood? = nil
    @State private var breathingText = false
    
    var body: some View {
        ZStack {
            // Elegant pristine white background
            Color.white.ignoresSafeArea()
            

            
            if selectedMood == nil {
                // Typographic split screen interaction
                VStack(spacing: 0) {
                    
                    // TOP HALF: happy.
                    ZStack {
                        Color.white.opacity(0.001) // Forces fullscreen touch detection
                        Text("happy.")
                            .font(.custom("DelaGothicOne-Regular", size: 48))
                            .fontWeight(.light)
                            .italic()
                            .kerning(1.5)
                            .foregroundColor(Color.black.opacity(0.85))
                            .scaleEffect(breathingText ? 1.02 : 0.98)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { completeSelection(mood: .happy) }
                    
                    // CENTER
                    Text("How are you feeling?")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(Color.black.opacity(0.3))
                        .kerning(1.2)
                        .padding(.vertical, 20)
                    
                    // BOTTOM HALF: sad.
                    ZStack {
                        Color.white.opacity(0.001)
                        Text("sad.")
                            .font(.custom("DelaGothicOne-Regular", size: 48))
                            .fontWeight(.light)
                            .italic()
                            .kerning(1.5)
                            .foregroundColor(Color.black.opacity(0.85))
                            .scaleEffect(breathingText ? 0.98 : 1.02)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { completeSelection(mood: .sad) }
                    
                }
                .opacity(showText ? 1 : 0)
                .onAppear {
                    // Delay slightly to fade text in gracefully
                    withAnimation(.easeIn(duration: 1.5)) {
                        showText = true
                    }
                    withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                        breathingText.toggle()
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 1.1))
                ))
            } else {
                FeedbackView(mode: selectedMood!)
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: 1.5).delay(0.5)),
                        removal: .opacity
                    ))
            }
        }
    }
    
    func completeSelection(mood: Mood) {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        
        withAnimation(.easeIn(duration: 0.8)) {
            selectedMood = mood
        }
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    let mode: Mood
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text(mode == .happy ? "That's wonderful." : "Take a deep breath.")
                .font(.custom("DelaGothicOne-Regular", size: 34))
                .fontWeight(.light)
                .kerning(1.2)
                .foregroundColor(.black.opacity(0.9))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 1.0).delay(0.2), value: isVisible)
            
            Text(mode == .happy ? "Keep riding the wave.\nThe world is yours today." : "It is completely okay to feel this way.\nTomorrow is a new start.")
                .font(.custom("DelaGothicOne-Regular", size: 18))
                .foregroundColor(.black.opacity(0.5))
                .kerning(0.8)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 1.0).delay(1.2), value: isVisible)
        }
        .onAppear {
            isVisible = true
        }
    }
}

#Preview {
    TrackingView()
}
