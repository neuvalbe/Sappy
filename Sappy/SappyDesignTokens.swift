//
//  SappyDesignTokens.swift
//  Sappy
//
//  Created by Neuval Studio on 25/03/2026.
//

import SwiftUI

// MARK: - App Navigation State

/// Defines the top-level navigation states for the Sappy application.
///
/// The app launches directly into `.login`. The `.splash` case is retained
/// for a future reintroduction of the cinematic face-merge entrance.
enum AppState: Sendable, Equatable {
    /// Archived splash animation (face-merge entrance). Currently bypassed.
    case splash
    /// Authentication flow: country selection → sign-in options.
    case login
    /// Core experience: cinematic mood selection → feedback response.
    case tracking
}

// MARK: - Mood Model

/// Represents the binary mood choice available to the user.
///
/// The raw value is used for display labels and future Firestore document keys.
enum Mood: String, Sendable, CaseIterable {
    case happy = "happy"
    case sad = "sad"
}

// MARK: - Design Tokens

/// Centralized design token namespace for the Sappy brand system.
///
/// All colors, typography constants, animation timings, and layout metrics
/// are defined here to ensure a single source of truth across all views.
enum SappyDesign {

    // MARK: Colors

    /// Near-black used for primary text and logo strokes.
    static let textPrimary = Color(white: 0.1)

    /// Secondary text opacity level.
    static let textSecondaryOpacity: Double = 0.5

    /// Tertiary text opacity level (disclaimers, labels).
    static let textTertiaryOpacity: Double = 0.4

    /// Quaternary text opacity level (hint text, chevrons).
    static let textQuaternaryOpacity: Double = 0.3

    /// Input field background fill opacity.
    static let inputBackgroundOpacity: Double = 0.04

    /// Input field border stroke opacity.
    static let inputBorderOpacity: Double = 0.1

    /// Disabled button background opacity.
    static let disabledOpacity: Double = 0.2

    /// The signature Sappy brand gradient — vibrant red used for selected mood states.
    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.2, blue: 0.2),
            Color(red: 0.8, green: 0.0, blue: 0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Typography

    /// The universal typeface for all Sappy UI elements.
    static let fontFamily = "DelaGothicOne-Regular"

    // MARK: Layout

    /// Standard button height across all auth and action buttons.
    static let buttonHeight: CGFloat = 56

    /// Standard corner radius for buttons and input fields.
    static let cornerRadius: CGFloat = 16

    /// Horizontal content padding for auth screens.
    static let horizontalPadding: CGFloat = 32

    /// Bottom safe-area padding for auth screens.
    static let bottomPadding: CGFloat = 60

    // MARK: Tracking View Layout

    /// The logo frame size used in the TrackingView faces.
    static let trackingFaceSize: CGFloat = 80

    /// Line width for the TrackingView face strokes.
    static let trackingStrokeWidth: CGFloat = 10

    /// Vertical distance each face travels from center during the split animation.
    static let splitDistance: CGFloat = 180

    /// Vertical position of the selected face after mood selection.
    static let selectedFaceOffset: CGFloat = -180

    /// Vertical position of the dismissed face (slides off-screen).
    static let dismissedFaceOffset: CGFloat = 500

    /// Scale factor applied to the selected face.
    static let selectedFaceScale: CGFloat = 1.5

    /// Vertical offset for feedback content below the selected face.
    static let feedbackContentOffset: CGFloat = 80

    // MARK: Utilities

    /// Converts an ISO 3166-1 alpha-2 country code ("US", "GB") to its flag emoji ("🇺🇸", "🇬🇧").
    /// Returns the raw code if conversion fails.
    static func flagEmoji(for countryCode: String) -> String {
        guard countryCode.count == 2 else { return countryCode }
        
        let uppercased = countryCode.uppercased()
        
        // Strict guard: ONLY perform math on exact A-Z uppercase Latin letters.
        // If the string is already a flag emoji (from old UserDefaults), this prevents
        // mathematically double-shifting it into unassigned [?] Unicode space!
        let isLatin = uppercased.unicodeScalars.allSatisfy { 
            $0.value >= 65 && $0.value <= 90 
        }
        
        guard isLatin else { return countryCode }
        
        let base: UInt32 = 127397
        let scalars = uppercased.unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }
        
        var flag = ""
        flag.unicodeScalars.append(contentsOf: scalars)
        return flag.isEmpty ? countryCode : flag
    }
}

// MARK: - Squishable Button Style

/// A tactile button style that scales down on press for a physical, premium feel.
///
/// Used across all primary and secondary buttons in the app.
/// Scale factor: `0.96` on press, spring-back on release.
struct SquishableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
