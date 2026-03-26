//
//  SappyApp.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import FirebaseCore
import CoreText // Keep CoreText for font registration

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

/// Sappy iOS Entry Point
@main
struct SappyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Font registration logic remains in init() for proper setup before SwiftUI body
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
