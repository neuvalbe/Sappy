//
//  TrackingViewModel.swift
//  Sappy
//
//  Created by Neuval Studio on 26/03/2026.
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Tracking View Model

/// Manages real-time data sync with Firestore for live global mood counts.
///
/// ## Architecture (v2.0 — Production-Grade Atomic Writes)
/// - **`users/{uid}`**: Stores the user's current mood and country. This is the
///   source of truth for "what did I vote for?" — it follows the account across
///   devices, preventing double-counting.
/// - **`metrics/global_counts`**: Stores aggregated counts. Mutations use
///   `FieldValue.increment()` for atomic updates.
/// - **`WriteBatch`**: All multi-document writes use Firestore `WriteBatch` to
///   guarantee atomicity — either both the user doc and global counts update, or
///   neither does. This eliminates count drift from partial failures.
/// - **Startup flow**: `startSync()` reads `users/{uid}` first to hydrate local
///   state. If the user already voted on another device, no new increment fires.
/// - **`UserDefaults`**: Kept as a fast-launch cache only. Firestore overwrites it
///   on every sync.
@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var globalHappyCount: Int = 0
    @Published var globalSadCount: Int = 0
    @Published var happyCountryStats: [(String, Int)] = []
    @Published var sadCountryStats: [(String, Int)] = []

    // MARK: - Computed Metrics

    /// The user's active country code for UI display
    var activeCountry: String {
        return userCountry
    }

    /// Primary Metric: Percentage of world sharing the same mood
    var globalPercentage: Int {
        let total = globalHappyCount + globalSadCount
        guard total > 0, let mood = currentMood else { return 100 }
        let myGlobal = mood == .happy ? globalHappyCount : globalSadCount
        return Int(round((Double(myGlobal) / Double(total)) * 100))
    }

    /// Secondary Metric: Percentage of people in the active country sharing the same mood
    var localPercentage: Int {
        guard let mood = currentMood else { return 100 }
        
        let myLocalCount = (mood == .happy ? happyCountryStats : sadCountryStats)
            .first(where: { $0.0 == userCountry })?.1 ?? 0
            
        let oppositeLocalCount = (mood == .happy ? sadCountryStats : happyCountryStats)
            .first(where: { $0.0 == userCountry })?.1 ?? 0
            
        let totalLocal = myLocalCount + oppositeLocalCount
        
        // If snapshot implies 0 locally but user voted, it means snapshot is still incoming
        if totalLocal == 0 { return 100 }
        return Int(round((Double(myLocalCount) / Double(totalLocal)) * 100))
    }

    // MARK: - Persisted State (UserDefaults cache)

    /// The user's currently active mood vote, cached locally for fast relaunch.
    /// Firestore `users/{uid}` is the actual source of truth.
    var storedMood: String {
        get { UserDefaults.standard.string(forKey: "currentMood") ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentMood")
            objectWillChange.send()
        }
    }

    /// The user's country code, cached locally.
    /// Firestore `users/{uid}` is the actual source of truth.
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

    /// Prevents rapid-fire voting from corrupting state.
    /// Set `true` on vote, reset after 0.6s cooldown.
    private var isVoteCooldown = false

    init() {
        docRef = db.collection("metrics").document("global_counts")
    }

    // MARK: - Real-Time Sync

    /// Hydrates user state from Firestore, ensures global_counts exists,
    /// then attaches the snapshot listener.
    func startSync() {
        listener?.remove()

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let userDocRef = db.collection("users").document(uid)

        // Step 1: Read the user's server-side vote state
        userDocRef.getDocument { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("[Sappy] Failed to read user doc: \(error.localizedDescription)")
            }

            if let data = snapshot?.data() {
                // User doc exists — hydrate local cache from server truth
                let serverMood = data["mood"] as? String ?? ""
                let serverCountry = data["country"] as? String ?? ""

                if !serverMood.isEmpty {
                    self.storedMood = serverMood
                }
                if !serverCountry.isEmpty {
                    self.storedCountry = serverCountry
                }
            } else if !self.storedMood.isEmpty || !self.storedCountry.isEmpty {
                // No user doc but local state exists — migrate to Firestore
                var migrationData: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
                if !self.storedMood.isEmpty { migrationData["mood"] = self.storedMood }
                if !self.storedCountry.isEmpty { migrationData["country"] = self.storedCountry }
                userDocRef.setData(migrationData, merge: true) { error in
                    if let error {
                        print("[Sappy] Migration write failed: \(error.localizedDescription)")
                    }
                }
            }

            // Step 2: Ensure global_counts exists, then attach listener
            self.ensureGlobalDocAndListen()
        }
    }

    /// Ensures `metrics/global_counts` exists, then attaches the snapshot listener.
    private func ensureGlobalDocAndListen() {
        docRef.getDocument { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("[Sappy] Failed to read global_counts: \(error.localizedDescription)")
            }

            if let snapshot, snapshot.exists {
                self.attachListener()
            } else {
                self.docRef.setData([
                    "total_happy": 0,
                    "total_sad": 0,
                    "countries": [String: Any]()
                ]) { error in
                    if let error {
                        print("[Sappy] Seed write failed: \(error.localizedDescription)")
                    }
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

    /// Submits or changes the user's mood vote using an atomic `WriteBatch`.
    ///
    /// - **Same mood**: No-op.
    /// - **First vote**: Increments mood + country in global_counts, writes to users/{uid}.
    /// - **Vote swap**: Decrements old + increments new, updates users/{uid}.
    ///
    /// Both the user doc write and global counts update happen in a single
    /// `WriteBatch` — either both succeed or neither does. This prevents count
    /// drift from partial write failures.
    func vote(mood: Mood) {
        let previousMood = currentMood
        guard previousMood != mood else { return }
        guard !isVoteCooldown else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Cooldown: block rapid taps for 0.6s
        isVoteCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.isVoteCooldown = false
        }

        storedMood = mood.rawValue
        let country = userCountry

        // Atomic batch: user doc + global counts in one transaction
        let batch = db.batch()
        let userDocRef = db.collection("users").document(uid)

        batch.setData([
            "mood": mood.rawValue,
            "country": country,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: userDocRef, merge: true)

        if let oldMood = previousMood {
            // Swap: decrement old, increment new
            batch.updateData([
                "total_\(oldMood.rawValue)": FieldValue.increment(Int64(-1)),
                "total_\(mood.rawValue)": FieldValue.increment(Int64(1)),
                "countries.\(country).\(oldMood.rawValue)": FieldValue.increment(Int64(-1)),
                "countries.\(country).\(mood.rawValue)": FieldValue.increment(Int64(1))
            ], forDocument: docRef)
        } else {
            // First vote
            batch.updateData([
                "total_\(mood.rawValue)": FieldValue.increment(Int64(1)),
                "countries.\(country).\(mood.rawValue)": FieldValue.increment(Int64(1))
            ], forDocument: docRef)
        }

        batch.commit { error in
            if let error {
                print("[Sappy] Vote batch write failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sign Out

    /// Signs the user out, retracting their active vote first.
    /// Only clears mood state — country and hasCompletedFirstSignUp are UX cache
    /// that should persist so returning users skip the country picker.
    func signOut() {
        listener?.remove()
        listener = nil

        // Retract vote first — auth.signOut() is chained AFTER the batch
        // commits to prevent invalidating the token before the write succeeds.
        retractVote { [weak self] in
            guard let self else { return }

            do {
                try Auth.auth().signOut()
            } catch {
                print("[Sappy] Sign out failed: \(error.localizedDescription)")
            }

            // Only clear mood — full wipe is reserved for deleteAccount()
            self.storedMood = ""
        }
    }

    // MARK: - Delete Account

    /// Permanently deletes the user's Firebase account and Firestore data.
    ///
    /// Operations are chained sequentially to prevent race conditions:
    /// 1. Retract active vote (atomic batch)
    /// 2. Delete `users/{uid}` document
    /// 3. Delete Firebase Auth account
    /// 4. Clear all local persisted state
    func deleteAccount(completion: @escaping @MainActor (String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion("No signed-in user found.")
            return
        }

        let uid = user.uid

        // Step 1: Retract vote (atomic batch) → then chain remaining steps
        retractVote { [weak self] in
            guard let self else { return }

            // Step 2: Delete user Firestore document
            self.db.collection("users").document(uid).delete { [weak self] error in
                if let error {
                    print("[Sappy] User doc delete failed: \(error.localizedDescription)")
                }

                // Step 3: Delete Firebase Auth account
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

                        // Step 4: Clear all local state
                        self?.listener?.remove()
                        self?.listener = nil
                        self?.clearPersistedState()
                        completion(nil)
                    }
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Decrements the user's active vote from Firestore and clears the user doc mood.
    ///
    /// Uses an atomic `WriteBatch` to ensure both the global decrement and user doc
    /// clear succeed or fail together. Accepts an optional completion handler for
    /// chaining (used by `deleteAccount()`).
    ///
    /// `signOut()` calls this fire-and-forget (acceptable — sign-out is not destructive).
    private func retractVote(completion: (() -> Void)? = nil) {
        guard let mood = currentMood else {
            completion?()
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?()
            return
        }

        let country = userCountry
        let batch = db.batch()

        // Decrement global counts
        batch.updateData([
            "total_\(mood.rawValue)": FieldValue.increment(Int64(-1)),
            "countries.\(country).\(mood.rawValue)": FieldValue.increment(Int64(-1))
        ], forDocument: docRef)

        // Clear mood in user doc
        let userDocRef = db.collection("users").document(uid)
        batch.updateData([
            "mood": "",
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: userDocRef)

        batch.commit { error in
            if let error {
                print("[Sappy] Retract batch write failed: \(error.localizedDescription)")
            }
            completion?()
        }
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
