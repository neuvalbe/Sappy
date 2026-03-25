//
//  SappyApp.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import CoreText

/// The root entry point for the Sappy application.
///
/// Registers the custom `Dela Gothic One` typeface at process scope
/// before the first SwiftUI render pass. Falls back to the system font
/// with a console warning if the bundle resource is missing.
@main
struct SappyApp: App {
    init() {
        if let fontURL = Bundle.main.url(forResource: "DelaGothicOne-Regular", withExtension: "ttf") {
            var errorRef: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &errorRef) {
                let description = errorRef?.takeRetainedValue().localizedDescription ?? "unknown"
                print("[Sappy] ⚠️ Font registration failed: \(description)")
            }
        } else {
            print("[Sappy] ⚠️ DelaGothicOne-Regular.ttf not found in bundle")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
