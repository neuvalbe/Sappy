# Sappy

> No app asks you how you feel.

A minimalist, cinematic mood-tracking iOS app + web companion. Choose happy or sad — see the world respond in real time.

---

## What is Sappy?

Sappy strips mood tracking down to one question: **how do you feel right now?**

Tap the happy face or the sad face. That's it. The app responds with an empathetic message, a live global counter of how many people share your mood, and a per-country breakdown — all in real time via Firestore.

The brand identity is the `):)` logo — two mirrored arcs sharing colon eyes.

---

## Features

### iOS App
- **One-tap voting** — Choose happy or sad with a single tap
- **Real-time global percentage** — See what percentage of the world feels the same way, right now
- **Local percentage** — Per-country mood stats dynamically calculated against local votes
- **Cinematic UI** — Physics-based spring animations, breathing idle state, staggered reveals
- **Mood-colored subtitles** — Brand yellow glow (happy), steel blue glow (sad)
- **Cross-device sync** — Vote state follows your account, not your device
- **Vote deduplication** — Same account on multiple devices = one vote
- **Sign In with Apple** — Native Apple credential flow via Firebase
- **Email/Password auth** — Alternative sign-in with Firebase Auth
- **Account deletion** — App Store 5.1.1(v) compliant, full data wipe

### Web Companion (`web/`)
- **Ambient Aura** — Cinematic orbital gradient + SVG fractal noise background, mood-reactive
- **Read-only mirror** — Displays the user's current mood state from the iOS app
- **Real-time Firestore** — `onSnapshot` listeners for user mood + global metrics
- **Profile drawer** — User info, mood indicator, legal docs, support, account management
- **Sign-in only** — No account creation; users create accounts via the iOS app
- **Static export** — `next build` → `web/out/` → Firebase Hosting

---

## Tech Stack

| Layer | Technology |
|---|---|
| **iOS Platform** | iOS 17+ (SwiftUI) |
| **iOS Language** | Swift 5.9+ |
| **Web Framework** | Next.js 16 (React 19, TypeScript 6) |
| **Web Styling** | Tailwind CSS 4 + Framer Motion 12 |
| **Auth** | Firebase Authentication (Apple + Email/Password) |
| **Database** | Cloud Firestore (real-time snapshot listeners) |
| **Hosting** | Firebase Hosting (static export) |
| **Font** | Dela Gothic One (bundled on iOS, Google Fonts on web) |
| **iOS Architecture** | MVVM (`TrackingViewModel` → `TrackingView`) |

---

## Project Structure

```
Sappy/
├── Sappy/                          # iOS app (Swift/SwiftUI)
│   ├── SappyApp.swift              # @main entry, font registration
│   ├── SappyDesignTokens.swift     # Types, design tokens, SquishableButtonStyle
│   ├── ContentView.swift           # Root state router (.login ↔ .tracking)
│   ├── AuthHelper.swift            # Centralized post-auth logic (country persist, state transition)
│   ├── LoginView.swift             # 2-step auth: country picker → sign-in options
│   ├── SappyAuthView.swift         # Email/password auth sheet
│   ├── SappyLegalView.swift        # Terms of Service & Privacy Policy
│   ├── TrackingView.swift          # Cinematic mood selection + feedback
│   ├── TrackingViewModel.swift     # Firestore sync, atomic vote logic, account mgmt
│   ├── SappySettingsView.swift     # Sign-out + account deletion
│   └── SappyLogoShape.swift        # SVG path data for ):) logo
│
├── web/                            # Web companion (Next.js)
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx          # Root layout, Dela Gothic One via Google Fonts
│   │   │   ├── page.tsx            # State machine: auth → Firestore listeners → Aura
│   │   │   ├── globals.css         # Tailwind + custom font-face
│   │   │   ├── terms/page.tsx      # Public Terms of Service (no auth required)
│   │   │   └── privacy/page.tsx    # Public Privacy Policy (no auth required)
│   │   ├── components/
│   │   │   ├── AuthModal.tsx       # Sign-in only (no sign-up) email/password form
│   │   │   ├── AuraBackground.tsx  # Framer Motion orbital gradients + SVG noise filter
│   │   │   ├── AuraContent.tsx     # Typography overlay: mood word, dual global/local % stats
│   │   │   └── ProfileDrawer.tsx   # Profile, legal docs, support, sign-out, delete account
│   │   └── lib/
│   │       └── firebase.ts         # Firebase init from env vars
│   ├── next.config.mjs             # Static export config (output: 'export')
│   ├── .env.local                  # Firebase credentials (gitignored)
│   └── package.json                # Dependencies
│
├── firebase.json                   # Firestore + Hosting config
├── firestore.rules                 # Security rules (field-validated)
├── firestore.indexes.json          # Index definitions
│
├── read_firestore.js               # Admin: read global_counts
├── seed_firestore.js               # Admin: wipe + re-seed
├── wipe_firestore.js               # Admin: reset all data
│
├── ARCHITECTURE.md                 # Architecture guide + React replication spec
├── TECH_SPECS.md                   # Technical specs, file roles, data flow
├── HANDOVER.md                     # Agent handover document
└── README.md                       # This file
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

- **Atomic writes** — All multi-document mutations use `WriteBatch` (user doc + global counts succeed or fail together) — on both iOS and web
- **Sequential delete** — `deleteAccount()` chains retract → doc delete → auth delete (iOS via callbacks, web via async/await)
- **Error logging** — All Firestore writes log failures via `[Sappy]`-prefixed console messages
- **Field-validated rules** — `metrics` writes restricted to known fields with type validation
- **Vote cooldown** (0.6s, iOS only) — Prevents rapid-tap race conditions
- **Count flooring** — `max(0, ...)` / `Math.max(0, ...)` handles transient negatives
- **Optimistic country guardrail** (iOS) — Shows user's country immediately before snapshot arrives
- **Self-healing seed** (iOS) — Creates `global_counts` if missing

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

### iOS
1. Open `Sappy.xcodeproj` in Xcode 15+
2. Ensure `GoogleService-Info.plist` is present in `Sappy/`
3. Select target device (iOS 17+)
4. Build and run (⌘R)

### Web Companion
1. `cd web && npm install`
2. Ensure `web/.env.local` exists with Firebase credentials (see Environment section below)
3. `npm run dev` — local development at `localhost:3000`
4. `npm run build` — static export to `web/out/`
5. `firebase deploy --only hosting` — deploy to Firebase Hosting (from project root)

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
- **Hosting**: Static export from `web/out/`

---

## Documentation

| File | Contents |
|---|---|
| `ARCHITECTURE.md` | Full architecture guide, data flow, and state machines |
| `TECH_SPECS.md` | Technical specs, file roles, state flow, data architecture |
| `HANDOVER.md` | Agent handover: workflow rules, file map, data flows, status |

---

## License

Private. All rights reserved.
