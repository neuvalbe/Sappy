//
//  TrackingViewModel.swift
//  Sappy
//
//  Created by Neuval Studio on 26/03/2026.
//

import Foundation

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Tracking View Model

/// Manages real-time data sync with Firestore for live global mood counts.
///
/// ## Architecture
/// - **Single document**: All global state lives in `metrics/global_counts`.
/// - **Single write strategy**: Every mutation uses `updateData` with dot-notation
///   paths. The document is guaranteed to exist via `ensureDocument()` on first sync.
/// - **No optimistic updates**: The snapshot listener is the single source of truth
///   for all `@Published` state. This eliminates double-counting, flicker, and
///   desync between local and remote state.
/// - **Persistence**: The user's vote is stored in `UserDefaults` so it survives
///   app restarts. Firestore is the source of truth for counts; UserDefaults is
///   the source of truth for "what did I vote for?"
@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var globalHappyCount: Int = 0
    @Published var globalSadCount: Int = 0
    @Published var happyCountryStats: [(String, Int)] = []
    @Published var sadCountryStats: [(String, Int)] = []

    // MARK: - Persisted State

    /// The user's currently active mood vote, persisted across sessions.
    var storedMood: String {
        get { UserDefaults.standard.string(forKey: "currentMood") ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentMood")
            objectWillChange.send()
        }
    }

    /// The user's country code, set during onboarding.
    private var storedCountry: String {
        get { UserDefaults.standard.string(forKey: "userCountry") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "userCountry") }
    }

    /// Computed accessor for the persisted mood.
    var currentMood: Mood? {
        switch storedMood {
        case Mood.happy.rawValue: return .happy
        case Mood.sad.rawValue: return .sad
        default: return nil
        }
    }

    /// The country code used for Firestore bucketing.
    /// Falls back to device locale if onboarding country was never set.
    private var userCountry: String {
        if !storedCountry.isEmpty { return storedCountry }
        return Locale.current.region?.identifier ?? "US"
    }

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let docRef: DocumentReference

    init() {
        docRef = db.collection("metrics").document("global_counts")
    }

    // MARK: - Real-Time Sync

    /// Ensures the global_counts document exists, then attaches a snapshot listener.
    func startSync() {
        listener?.remove()

        // Step 1: Guarantee the document exists BEFORE attaching the listener.
        // Using a completion handler to avoid a race where vote() fires updateData
        // before the seed document is created.
        docRef.getDocument { [weak self] snapshot, error in
            guard let self else { return }

            if let snapshot, snapshot.exists {
                self.attachListener()
            } else {
                self.docRef.setData([
                    "total_happy": 0,
                    "total_sad": 0,
                    "countries": [String: Any]()
                ]) { _ in
                    self.attachListener()
                }
            }
        }
    }
    
    /// Attaches the real-time snapshot listener to the global_counts document.
    private func attachListener() {
        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self, let document = snapshot, let data = document.data() else { return }

            // Floor at 0 — stale retract operations can cause transient negatives
            self.globalHappyCount = max(0, data["total_happy"] as? Int ?? 0)
            self.globalSadCount = max(0, data["total_sad"] as? Int ?? 0)

            var hStats = [(String, Int)]()
            var sStats = [(String, Int)]()

            if let countriesData = data["countries"] as? [String: Any] {
                for (code, value) in countriesData {
                    guard let stats = value as? [String: Any] else { continue }
                    let happyCount = max(0, (stats["happy"] as? NSNumber)?.intValue ?? 0)
                    let sadCount = max(0, (stats["sad"] as? NSNumber)?.intValue ?? 0)

                    if happyCount > 0 { hStats.append((code, happyCount)) }
                    if sadCount > 0 { sStats.append((code, sadCount)) }
                }
            }

            self.happyCountryStats = hStats.sorted { $0.1 > $1.1 }
            self.sadCountryStats = sStats.sorted { $0.1 > $1.1 }
        }
    }

    // MARK: - Vote

    /// Submits or changes the user's mood vote.
    ///
    /// - **Same mood**: No-op.
    /// - **First vote**: Single `updateData` incrementing the mood + country.
    /// - **Vote swap**: Single `updateData` decrementing old + incrementing new.
    ///
    /// No optimistic local updates — the snapshot listener handles all UI state.
    func vote(mood: Mood) {
        let previousMood = currentMood
        guard previousMood != mood else { return }

        storedMood = mood.rawValue
        let country = userCountry

        if let oldMood = previousMood {
            // Swap: decrement old, increment new — single atomic updateData
            docRef.updateData([
                "total_\(oldMood.rawValue)": FieldValue.increment(Int64(-1)),
                "total_\(mood.rawValue)": FieldValue.increment(Int64(1)),
                "countries.\(country).\(oldMood.rawValue)": FieldValue.increment(Int64(-1)),
                "countries.\(country).\(mood.rawValue)": FieldValue.increment(Int64(1))
            ])
        } else {
            // First vote: single updateData
            docRef.updateData([
                "total_\(mood.rawValue)": FieldValue.increment(Int64(1)),
                "countries.\(country).\(mood.rawValue)": FieldValue.increment(Int64(1))
            ])
        }
    }

    // MARK: - Sign Out

    /// Signs the user out, retracting their active vote first.
    func signOut() {
        listener?.remove()
        listener = nil
        retractVote()

        do {
            try Auth.auth().signOut()
        } catch {
            print("[Sappy] Sign out failed: \(error.localizedDescription)")
        }

        clearPersistedState()
    }

    // MARK: - Delete Account

    /// Permanently deletes the user's Firebase account.
    func deleteAccount(completion: @escaping @MainActor (String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion("No signed-in user found.")
            return
        }

        retractVote()

        user.delete { [weak self] error in
            Task { @MainActor [weak self] in
                if let error {
                    let code = (error as NSError).code
                    if code == AuthErrorCode.requiresRecentLogin.rawValue {
                        completion("For security, please sign out and sign back in, then try again.")
                    } else {
                        completion(error.localizedDescription)
                    }
                    return
                }

                self?.listener?.remove()
                self?.listener = nil
                self?.clearPersistedState()
                completion(nil)
            }
        }
    }

    // MARK: - Private Helpers

    /// Decrements the user's active vote from Firestore.
    private func retractVote() {
        guard let mood = currentMood else { return }
        let country = userCountry

        docRef.updateData([
            "total_\(mood.rawValue)": FieldValue.increment(Int64(-1)),
            "countries.\(country).\(mood.rawValue)": FieldValue.increment(Int64(-1))
        ])
    }

    /// Resets all user-specific persisted state.
    private func clearPersistedState() {
        storedMood = ""
        storedCountry = ""
        UserDefaults.standard.removeObject(forKey: "hasCompletedFirstSignUp")
    }

    deinit {
        listener?.remove()
    }
}
