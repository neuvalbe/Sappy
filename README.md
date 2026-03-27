# Sappy

> No app asks you how you feel.

A minimalist, cinematic mood-tracking iOS app. Choose happy or sad — see the world respond in real time.

---

## What is Sappy?

Sappy strips mood tracking down to one question: **how do you feel right now?**

Tap the happy face or the sad face. That's it. The app responds with an empathetic message, a live global counter of how many people share your mood, and a per-country breakdown — all in real time via Firestore.

The brand identity is the `):)` logo — a merged sad `):(` and happy `(:)` face sharing colon eyes.

---

## Features

- **One-tap voting** — Choose happy or sad with a single tap
- **Real-time global counter** — See how many people feel the same way, right now
- **Country breakdown** — Per-country mood stats displayed as capsules (ISO 3166-1 alpha-2)
- **Cinematic UI** — Physics-based spring animations, breathing idle state, staggered reveals
- **Mood-colored subtitles** — Brand yellow glow (happy), steel blue glow (sad)
- **Cross-device sync** — Vote state follows your account, not your device
- **Vote deduplication** — Same account on multiple devices = one vote
- **Sign In with Apple** — Native Apple credential flow via Firebase
- **Email/Password auth** — Alternative sign-in with Firebase Auth
- **Account deletion** — App Store 5.1.1(v) compliant, full data wipe

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Platform** | iOS 17+ (SwiftUI) |
| **Language** | Swift 5.9+ |
| **Auth** | Firebase Authentication (Apple + Email/Password) |
| **Database** | Cloud Firestore (real-time snapshot listeners) |
| **Font** | Dela Gothic One (bundled) |
| **Architecture** | MVVM (`TrackingViewModel` → `TrackingView`) |

---

## Project Structure

```
Sappy/
├── SappyApp.swift              # @main entry, font registration
├── SappyDesignTokens.swift     # Types, design tokens, SquishableButtonStyle
├── ContentView.swift           # Root state router (.login ↔ .tracking)
├── AuthHelper.swift            # Centralized post-auth logic (country persist, state transition)
├── LoginView.swift             # 2-step auth: country picker → sign-in options
├── SappyAuthView.swift         # Email/password auth sheet
├── SappyLegalView.swift        # Terms of Service & Privacy Policy
├── TrackingView.swift          # Cinematic mood selection + feedback
├── TrackingViewModel.swift     # Firestore sync, atomic vote logic, account mgmt
├── SappySettingsView.swift     # Sign-out + account deletion
└── SappyLogoShape.swift        # SVG path data for ):) logo
```

---

## Data Architecture

### Firestore Collections

```
metrics/global_counts              ← Aggregated mood counts (public read)
  total_happy: Int
  total_sad: Int
  countries: { "US": { happy: Int, sad: Int }, ... }

users/{uid}                        ← Per-user vote state (owner access only)
  mood: "happy" | "sad" | ""
  country: "US"                    ← ISO 3166-1 alpha-2
  updatedAt: Timestamp
```

### State Stores

| Store | Purpose | Scope |
|---|---|---|
| Firebase Auth (Keychain) | Authentication session | Per-device, survives reinstall |
| UserDefaults | Fast-launch cache | Per-device, cache only |
| Firestore `users/{uid}` | **Source of truth** for vote state | Per-account, cross-device |
| Firestore `metrics/global_counts` | Global aggregates | Shared, real-time |

### Resilience

- **Atomic writes** — All multi-document mutations use `WriteBatch` (user doc + global counts succeed or fail together)
- **Sequential delete** — `deleteAccount()` chains retract → doc delete → auth delete via callbacks
- **Error logging** — All Firestore writes log failures via `[Sappy]`-prefixed console messages
- **Field-validated rules** — `metrics` writes restricted to known fields with type validation
- **Vote cooldown** (0.6s) — Prevents rapid-tap race conditions
- **Count flooring** — `max(0, ...)` handles transient negatives
- **Optimistic country guardrail** — Shows user's country immediately before snapshot arrives
- **Self-healing seed** — Creates `global_counts` if missing
- **State migration** — Pre-v1.5 UserDefaults data auto-migrates to Firestore

---

## Security Rules

```
match /metrics/{doc} {
  allow read: if true;
  allow write: if request.auth != null
    && request.resource.data.keys().hasOnly(['total_happy', 'total_sad', 'countries'])
    && request.resource.data.total_happy is int
    && request.resource.data.total_sad is int;
}

match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## Build & Run

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator
- Firebase project (`sappy-caa9e`) with `GoogleService-Info.plist` in the bundle

### Steps
1. Clone the repository
2. Open `Sappy.xcodeproj` in Xcode
3. Ensure `GoogleService-Info.plist` is present in the `Sappy/` directory
4. Select your target device
5. Build and run (⌘R)

### Admin Scripts

| Script | Purpose |
|---|---|
| `node read_firestore.js` | Read current `global_counts` document |
| `node seed_firestore.js` | Wipe and re-seed `global_counts` to clean state |
| `node wipe_firestore.js` | Reset all Firestore data (metrics + users) |

> Note: Admin scripts require `firebase-admin` SDK credentials (Application Default or service account).

---

## Firebase Project

- **Project ID**: `sappy-caa9e`
- **Region**: `eur3` (Europe)
- **Auth Providers**: Sign In with Apple, Email/Password
- **Firestore Rules**: Deployed via `firestore.rules`

---

## Documentation

| File | Contents |
|---|---|
| `ARCHITECTURE.md` | Full architecture guide + React Native replication spec |
| `TECH_SPECS.md` | Technical specs, file roles, state flow, data architecture |

---

## Android

The Firebase backend is platform-agnostic and ready for Android. See `ARCHITECTURE.md` Section 10 for the full React Native implementation guide including:
- Component mapping (SwiftUI → React)
- Animation specifications
- Haptic feedback equivalents
- Minimum dependencies

---

## License

Private. All rights reserved.
