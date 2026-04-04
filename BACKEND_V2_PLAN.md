# Sappy — Phase 2: Logic, UI Polish, and Cloud Migration

## 1. Goal
This is the master blueprint that combines fixing the critical iOS logic bugs, polishing the UI presentation (auth text colors & face split animations), and safely migrating the backend to Cloud Functions. The previous Backend V2 plan would have *crashed* the app if we didn't fix the iOS Onboarding logic first.

---

## 2. Part 1: Critical Logic Architecture (Fix First)

If we don't fix these, the Backend V2 migration will physically crash during onboarding because the new Firebase Security Rules explicitly ban iOS from writing to the `mood` field.

### A. Invert Onboarding & Stop Blind Overwrites
- **Files Affected**: `LoginView.swift`, `AuthHelper.swift`
- **The Issue**: Currently, users select a country first, then sign in. Upon success, `AuthHelper` blindly executes `.setData(["mood": ""])`. If an existing user logs into a new device, this corrupts their vote history.
- **The Solution**: 
  1. We will swap the flow: **Sign In First**, then gracefully ask for Country *only if* the user's Firestore document is brand new or missing a country.
  2. `AuthHelper` will be stripped of its `"mood"` property write. It will only update `"country"` and `updatedAt`. This fixes the phantom vote bug permanently and correctly aligns with our Backend V2 security rules.

### B. Real-Time User State Sync
- **Files Affected**: `TrackingViewModel.swift`
- **The Issue**: The app reads `users/{uid}` via `.getDocument()` only once at startup. If the mood gets modified externally (or cleared by the backend logic), iOS won't update its UI.
- **The Solution**: Change to `.addSnapshotListener()` so the iOS UI reacts instantaneously to changes in the user's personal vote state.

---

## 3. Part 2: UI / UX Polish

### A. Fix Invisible Auth Text (Dark Mode Clash)
- **Files Affected**: `SappyAuthView.swift`
- **The Issue**: The text inside `SappyTextField` is turning white against a white background when the device is in dark mode.
- **The Solution**: Explicitly enforce `.foregroundColor(SappyDesign.textPrimary)` inside `SappyTextField`.

### B. Adaptive Split-Face Colors
- **Files Affected**: `TrackingView.swift`
- **The Issue**: During the opening cinematic, as the faces split across the black and white background boundaries, they disappear into the background.
- **The Solution**: Utilize SwiftUI's `.blendMode(.difference)` or a mask to dynamically invert the face colors based on the sliding background.

### C. The 100% Grammar Fix
- **Files Affected**: `TrackingView.swift`
- **The Issue**: "100% of people in Greece feel happy" looks weird if you are the only user in the country.
- **The Solution**: Add a check: if `totalLocal == 1`, show text like: "You are the first to feel [mood] in [Country]!".

### D. Compliance Box Permanent Fix
- **Files Affected**: `Info.plist`
- **The Solution**: Add the `ITSAppUsesNonExemptEncryption` key set to `NO`.

---

## 4. Part 3: Backend V2 — Cloud Functions

Once iOS is stabilized, execute the Cloud Migration. The logic remains excellent, but now rests on a fixed iOS foundation.

### The Functions
1. **`castVote`**: Atomic Cloud Function that securely decrements `previousMood` and increments new mood via transaction.
2. **`retractVote`**: Safely clears a user's vote upon sign-out / deletion.

### The Security Lockdown
`firestore.rules` will change exactly to this:
```javascript
match /metrics/{doc} {
  allow read: if true;
  allow write: if false;  // ONLY Cloud Functions can modify counts
}
match /users/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId
    && request.resource.data.keys().hasOnly(['country', 'updatedAt', 'mood'])
    && !('mood' in request.resource.data.diff(resource.data).affectedKeys());
}
```

---

## 5. Part 4: Proposed New Features
*(To be populated by User)*
