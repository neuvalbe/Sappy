# Sappy Technical Specifications

> Source of truth: **the code**. This document describes.

---

## System Overview

| Attribute | Value |
|---|---|
| **Product** | Sappy — minimalist mood tracker |
| **Platforms** | iOS 17+ (primary), Web (companion mirror) |
| **Backend** | Firebase (Auth + Firestore + Hosting) |
| **Project ID** | `sappy-caa9e` |
| **Region** | `eur3` (Europe) |
| **Architecture** | iOS: MVVM · Web: Component tree with Firestore listeners |

---

## iOS Technical Specs

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| Firebase iOS SDK | 11.x | Auth, Firestore |
| SwiftUI | iOS 17+ | UI framework |
| AuthenticationServices | iOS 17+ | Sign In with Apple |
| Swift | 5.9+ | Language |

### File → Responsibility Map

| File | LOC (approx) | Role |
|---|---|---|
| `SappyApp.swift` | 25 | @main entry, font registration |
| `SappyDesignTokens.swift` | 149 | Types, color tokens, `SquishableButtonStyle` |
| `ContentView.swift` | 42 | Root state router (`.login` ↔ `.tracking`) |
| `AuthHelper.swift` | 69 | Post-auth: country persist → state transition |
| `LoginView.swift` | 182 | 2-step auth: country picker → sign-in options |
| `SappyAuthView.swift` | 165 | Email/password auth sheet |
| `SappyLegalView.swift` | 133 | Terms of Service + Privacy Policy |
| `TrackingView.swift` | 373 | Cinematic mood selection + feedback |
| `TrackingViewModel.swift` | 375 | Firestore sync, atomic vote, account lifecycle |
| `SappySettingsView.swift` | 251 | Sign-out + delete account UI |
| `SappyLogoShape.swift` | 68 | SVG path data for `:)` / `:(` |

### State Flow (iOS)

```
App Launch
  │
  ├── Auth.auth().currentUser != nil
  │     └── AppState = .tracking
  │           └── TrackingViewModel.init()
  │                 ├── listenToUserMood()    → onSnapshot(users/{uid})
  │                 └── listenToGlobalCounts() → onSnapshot(metrics/global_counts)
  │
  └── Auth.auth().currentUser == nil
        └── AppState = .login
              └── LoginView
                    ├── Country picker (ISO 3166-1)
                    ├── Sign In with Apple
                    └── Email/Password → SappyAuthView
                          └── AuthHelper.handlePostAuth()
                                ├── Persist country to users/{uid}
                                └── AppState = .tracking
```

### Vote Logic (iOS)

```swift
submitVote(_ mood: Mood):
  1. Cooldown check (0.6s debounce)
  2. If same mood → retractVote() (toggle off)
  3. If different mood → retractVote() first, then submit new
  4. WriteBatch:
     - metrics/global_counts.total_{mood} += 1
     - metrics/global_counts.countries.{CC}.{mood} += 1
     - users/{uid}.mood = "{mood}"
     - users/{uid}.updatedAt = serverTimestamp()
  5. batch.commit()

retractVote():
  1. Guard: currentMood must be "happy" or "sad"
  2. Guard: userCountry must exist
  3. WriteBatch:
     - metrics/global_counts.total_{mood} -= 1 (floored to 0)
     - metrics/global_counts.countries.{CC}.{mood} -= 1 (floored to 0)
     - users/{uid}.mood = ""
     - users/{uid}.updatedAt = serverTimestamp()
  4. batch.commit()
```

---

## Web Companion Technical Specs

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| Next.js | 16.2.1 | Framework (static export) |
| React | 19.x | UI library |
| TypeScript | 6.x | Language |
| Tailwind CSS | 4.x | Styling |
| Framer Motion | 12.x | Animations |
| Firebase JS SDK | 11.x | Auth + Firestore |

### Build & Output

| Config | Value |
|---|---|
| `output` | `"export"` (static HTML/JS/CSS) |
| `images.unoptimized` | `true` (no Node.js image server) |
| Output directory | `web/out/` |
| Hosting target | Firebase Hosting (`"public": "web/out"`) |

### File → Responsibility Map

| File | LOC (approx) | Role |
|---|---|---|
| `lib/firebase.ts` | 15 | Firebase SDK init from env vars |
| `app/layout.tsx` | 28 | Root layout, Dela Gothic One font |
| `app/page.tsx` | 146 | State machine: auth → listeners → render |
| `app/globals.css` | 25 | Tailwind config + overrides |
| `components/AuthModal.tsx` | 120 | Sign-in only form (no sign-up) |
| `components/AuraBackground.tsx` | 90 | Orbital gradients + SVG noise |
| `components/AuraContent.tsx` | 160 | Mood typography + stats + countries |
| `components/ProfileDrawer.tsx` | 480 | Profile, legal, support, account mgmt |

### State Flow (Web)

```
page.tsx mount
  │
  ├── onAuthStateChanged(null)
  │     └── Show AuthModal (sign-in only, no sign-up)
  │           └── signInWithEmailAndPassword()
  │                 └── onAuthStateChanged(user) → ↓
  │
  └── onAuthStateChanged(user)
        ├── onSnapshot(users/{uid})           → userMood state
        ├── onSnapshot(metrics/global_counts) → globalStats state
        └── Render:
              ├── AuraBackground (mood-reactive orbital gradients)
              ├── AuraContent (mood word + stats overlay)
              └── ProfileDrawer (slide-out from right)
```

### Account Deletion (Web — mirrors iOS)

```typescript
handleDeleteAccount():
  1. getDoc(users/{uid}) → read current mood + country
  2. If mood is "happy" or "sad":
     WriteBatch:
       - metrics/global_counts.total_{mood} -= 1
       - metrics/global_counts.countries.{CC}.{mood} -= 1
       - users/{uid}.mood = ""
       - users/{uid}.updatedAt = serverTimestamp()
     batch.commit()
  3. deleteDoc(users/{uid})
  4. deleteUser(auth) ← LAST (invalidates token)
```

> **Critical**: Steps 2-3 require valid auth. Step 4 destroys auth. Reordering = `permission-denied` + orphaned data.

---

## Firestore Data Schema

### `metrics/global_counts`

```
{
  total_happy: Int,           // Global happy vote count
  total_sad: Int,             // Global sad vote count
  countries: {
    "US": { happy: Int, sad: Int },
    "BE": { happy: Int, sad: Int },
    ...
  }
}
```

**Access**: Public read, authenticated write with field whitelist

### `users/{uid}`

```
{
  mood: "happy" | "sad" | "",   // Current vote state
  country: "US",                // ISO 3166-1 alpha-2
  updatedAt: Timestamp          // Server timestamp
}
```

**Access**: Owner read/write only (`auth.uid == userId`)

---

## Security Rules Summary

| Collection | Read | Write | Validation |
|---|---|---|---|
| `metrics/{doc}` | Anyone | Authenticated | Field whitelist: `total_happy`, `total_sad`, `countries`. Type: `int` for counters. |
| `users/{userId}` | Owner only | Owner only | `auth.uid == userId` |
| `/{everything_else}` | Denied | Denied | — |

Rule source: `firestore.rules`

---

## Resilience Features

| Feature | Platform | Implementation |
|---|---|---|
| Atomic writes | Both | `WriteBatch` (user + global in one commit) |
| Sequential delete | Both | retract → doc delete → auth delete |
| Count flooring | Both | `max(0, ...)` prevents negative counters |
| Vote cooldown | iOS only | 0.6s debounce via `allowInteraction` flag |
| Optimistic country | iOS only | Shows country immediately before snapshot |
| Self-healing seed | iOS only | Creates `global_counts` if missing |
| State migration | iOS only | Pre-v1.5 UserDefaults → Firestore |
| Error logging | Both | `[Sappy]`-prefixed console messages |

---

## Environment Configuration

### iOS
- `GoogleService-Info.plist` — Firebase credentials (bundled in target, gitignored)

### Web
- `web/.env.local` — Firebase credentials (gitignored)
  ```
  NEXT_PUBLIC_FIREBASE_API_KEY=...
  NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
  NEXT_PUBLIC_FIREBASE_PROJECT_ID=sappy-caa9e
  NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
  NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
  NEXT_PUBLIC_FIREBASE_APP_ID=...
  ```

---

## Known Limitations

| Item | Status | Detail |
|---|---|---|
| No "Forgot Password?" | Not implemented | Needs `Auth.auth().sendPasswordReset(withEmail:)` on iOS |
| Sign-in only on web | By design | Account creation happens exclusively on iOS |
| No offline support on web | By design | Web companion requires network for Firestore listeners |
| Public legal pages | Not deployed | Terms/Privacy should be accessible without auth for App Store |
| App Store screenshots | Not created | Required: 6.7" + 6.5" mandatory sizes |
