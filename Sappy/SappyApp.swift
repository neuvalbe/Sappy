//
//  SappyApp.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI
import CoreText

@main
struct SappyApp: App {
    init() {
        if let fontURL = Bundle.main.url(forResource: "DelaGothicOne-Regular", withExtension: "ttf") {
            var errorRef: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &errorRef)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
