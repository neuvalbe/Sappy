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
| `SappyApp.swift` | 43 | @main entry, font registration |
| `SappyDesignTokens.swift` | 148 | Types, color tokens, `SquishableButtonStyle` |
| `ContentView.swift` | 41 | Root state router (`.login` ↔ `.tracking`) |
| `AuthHelper.swift` | 68 | Post-auth: country persist → state transition |
| `LoginView.swift` | 356 | 2-step auth: country picker → sign-in options |
| `SappyAuthView.swift` | 333 | Email/password auth sheet |
| `SappyLegalView.swift` | 132 | Terms of Service + Privacy Policy |
| `TrackingView.swift` | 322 | Cinematic mood selection + feedback |
| `TrackingViewModel.swift` | 407 | Firestore sync, atomic vote, local/global % calculations |
| `SappySettingsView.swift` | 250 | Sign-out + delete account UI |
| `SappyLogoShape.swift` | 151 | SVG path data for `:)` / `:(` |

### State Flow (iOS)

```
App Launch
  │
  ├── Auth.auth().currentUser != nil
  │     └── AppState = .tracking
  │           └── TrackingViewModel.init()
  │                 └── startSync()
  │                       ├── getDocument(users/{uid})  → hydrates storedMood + storedCountry
  │                       └── ensureGlobalDocAndListen()
  │                             └── attachListener()    → addSnapshotListener(metrics/global_counts)
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
vote(mood: Mood):
  1. Guard: same mood as current → no-op (votes are locked in)
  2. Guard: isVoteCooldown → reject (0.6s debounce)
  3. Guard: user must be authenticated
  4. WriteBatch (atomic — all-or-nothing):
     IF previousMood exists (swap):
       - metrics/global_counts.total_{oldMood} -= 1
       - metrics/global_counts.countries.{CC}.{oldMood} -= 1
       - metrics/global_counts.total_{newMood} += 1
       - metrics/global_counts.countries.{CC}.{newMood} += 1
     ELSE (first vote):
       - metrics/global_counts.total_{mood} += 1
       - metrics/global_counts.countries.{CC}.{mood} += 1
     ALWAYS:
       - users/{uid}.mood = "{mood}"
       - users/{uid}.updatedAt = serverTimestamp()
  5. batch.commit() → on success: update storedMood locally

retractVote() (private — signOut + deleteAccount only):
  1. Guard: currentMood must be "happy" or "sad"
  2. Guard: user must be authenticated
  3. WriteBatch (atomic):
     - metrics/global_counts.total_{mood} -= 1
     - metrics/global_counts.countries.{CC}.{mood} -= 1
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
| `lib/firebase.ts` | 18 | Firebase SDK init from env vars |
| `app/layout.tsx` | 28 | Root layout, Dela Gothic One font |
| `app/page.tsx` | 153 | State machine: auth → listeners → render |
| `app/globals.css` | 20 | Tailwind config + overrides |
| `app/terms/page.tsx` | 93 | Public Terms of Service (no auth required) |
| `app/privacy/page.tsx` | 92 | Public Privacy Policy (no auth required) |
| `components/AuthModal.tsx` | 165 | Sign-in only form (no sign-up) |
| `components/AuraBackground.tsx` | 117 | Orbital gradients + SVG noise |
| `components/AuraContent.tsx` | 143 | Mood typography + stats + countries |
| `components/ProfileDrawer.tsx` | 481 | Profile, legal, support, account mgmt |

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
              ├── AuraContent (mood word + dual global/local % overlay)
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
| Vote cooldown | iOS only | 0.6s debounce via `isVoteCooldown` flag |
| Optimistic country | iOS only | Shows country immediately before snapshot |
| Self-healing seed | iOS only | Creates `global_counts` if missing |
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
| Sign-in only on web | By design | Account creation happens exclusively on iOS |
| No offline support on web | By design | Web companion requires network for Firestore listeners |
| Public legal pages | Done | `/terms` and `/privacy` routes accessible without auth |
| App Store screenshots | Not created | Required: 6.7" + 6.5" mandatory sizes |
