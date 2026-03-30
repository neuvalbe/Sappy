# Sappy Architecture Guide

> Living document. Source of truth: **the code**. This document describes, it does not define.
> **Note:** The architecture is currently being migrated to V2 to support Cloud Functions for security and massive concurrency.

---

## Table of Contents

1. [Overview](#overview)
2. [Platform Architecture](#platform-architecture)
3. [iOS Architecture](#ios-architecture)
4. [Web Companion Architecture](#web-companion-architecture)
5. [State Machine](#state-machine)
6. [Data Flow](#data-flow)
7. [Firestore Schema & Rules](#firestore-schema--rules)
8. [Account Deletion Flow](#account-deletion-flow)
9. [Design System](#design-system)
10. [Deployment](#deployment)

---

## Overview

Sappy is a two-platform system:

| Platform | Role | Stack |
|---|---|---|
| **iOS App** | Primary. Vote casting, mood tracking, global stats | SwiftUI, MVVM, Firebase Auth + Firestore |
| **Web Companion** | Read-only cinematic mirror of user's mood state | Next.js 16 (static export), React 19, Framer Motion, Firebase |

Both platforms share the same Firestore backend. The iOS app is the **write authority** (votes originate there). The web companion is a **read-only viewer** with one exception: account deletion (required for App Store compliance).

---

## Platform Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Firebase (sappy-caa9e)                              │
│                                                                             │
│  ┌─────────────────────────┐     ┌──────────────────────────────────────┐   │
│  │   Firebase Auth          │     │   Cloud Firestore                    │   │
│  │   • Sign In with Apple   │     │                                      │   │
│  │   • Email/Password       │     │   metrics/global_counts  (public r)  │   │
│  │                          │     │   users/{uid}            (owner rw)  │   │
│  └──────────┬───────────────┘     └──────────┬───────────────────────────┘   │
│             │                                │                              │
└─────────────┼────────────────────────────────┼──────────────────────────────┘
              │                                │
     ┌────────┴────────┐              ┌────────┴────────┐
     │   iOS App        │              │   Web Companion  │
     │   (SwiftUI)      │              │   (Next.js)      │
     │                  │              │                  │
     │   WRITES:        │              │   READS:         │
     │   • Cast vote    │              │   • User mood    │
     │   • Retract vote │              │   • Global stats │
     │   • Delete acct  │              │                  │
     │                  │              │   WRITES:        │
     │   READS:         │              │   • Delete acct  │
     │   • User mood    │              │     (retract +   │
     │   • Global stats │              │      doc delete  │
     │   • Country data │              │      + auth del) │
     └─────────────────┘              └─────────────────┘
```

---

## iOS Architecture

### MVVM Pattern

```
SappyApp.swift
  └── ContentView.swift (state router)
        ├── .login → LoginView.swift
        │               ├── Country picker (ISO 3166-1)
        │               ├── Sign In with Apple
        │               └── SappyAuthView.swift (email/password)
        │                     └── SappyLegalView.swift (terms/privacy)
        │
        └── .tracking → TrackingView.swift
                           ├── TrackingViewModel.swift (Firestore sync + vote logic)
                           └── SappySettingsView.swift (sign-out + delete)
```

### File Roles (iOS)

| File | Responsibility |
|---|---|
| `SappyApp.swift` | @main entry, font registration |
| `SappyDesignTokens.swift` | Types (`AppState`, `Mood`, color tokens), `SquishableButtonStyle` |
| `ContentView.swift` | State router: `.login` ↔ `.tracking` |
| `AuthHelper.swift` | Centralized post-auth: country persist → state transition |
| `LoginView.swift` | 2-step auth: country picker → sign-in options |
| `SappyAuthView.swift` | Email/password auth sheet |
| `SappyLegalView.swift` | Terms of Service + Privacy Policy scroll view |
| `TrackingView.swift` | Cinematic mood selection UI + feedback |
| `TrackingViewModel.swift` | Firestore snapshot listeners, atomic vote logic, account lifecycle |
| `SappySettingsView.swift` | Sign-out + account deletion UI |
| `SappyLogoShape.swift` | SVG path data for `:)` and `:(` logo |

### TrackingViewModel — Core Logic

```swift
// Snapshot listeners (real-time sync)
listenToUserMood()      → onSnapshot(users/{uid}) → updates local mood
listenToGlobalCounts()  → onSnapshot(metrics/global_counts) → updates counters

// Vote logic (atomic WriteBatch)
submitVote(mood)        → batch { increment global + set user mood } → commit
retractVote()           → batch { decrement global + clear user mood } → commit

// Account lifecycle
deleteAccount()         → retractVote() → deleteDoc(users/{uid}) → deleteUser(auth)
signOut()               → reset state → auth.signOut()
```

---

## Web Companion Architecture

### Component Tree

```
layout.tsx                          → Root: Dela Gothic One font, black bg
  └── page.tsx                      → State machine controller
        ├── NOT authed → AuthModal  → Email/password sign-in (no sign-up)
        └── authed → Firestore listeners
              ├── AuraBackground     → Orbital gradients + SVG noise
              ├── AuraContent        → Mood word, global % & local % metrics
              └── ProfileDrawer      → User info, legal, support, delete
```

### File Roles (Web)

| File | Responsibility |
|---|---|
| `lib/firebase.ts` | Firebase SDK init from `.env.local` |
| `app/layout.tsx` | Root layout, Dela Gothic One via Google Fonts |
| `app/page.tsx` | State machine: auth check → Firestore listeners → render |
| `app/globals.css` | Tailwind config + custom font-face |
| `components/AuthModal.tsx` | Sign-in only form (email + password) |
| `components/AuraBackground.tsx` | Framer Motion orbital gradients + SVG noise filter |
| `components/AuraContent.tsx` | Typography overlay: mood, subtitle, global & local % metrics |
| `components/ProfileDrawer.tsx` | Profile info, legal (Terms/Privacy), support, account mgmt |

### Page State Machine (`page.tsx`)

```
INIT
  ├── onAuthStateChanged(null) → show AuthModal
  └── onAuthStateChanged(user) → attach Firestore listeners
        ├── onSnapshot(users/{uid})           → userMood state
        ├── onSnapshot(metrics/global_counts) → globalStats state
        └── render: AuraBackground + AuraContent + ProfileDrawer
```

### Mood Colors (both platforms)

| Mood | Primary | Glow/Aura |
|---|---|---|
| Happy | `#FFFFFF` (white text) | `#FFE066` (warm yellow) |
| Sad | `#FFFFFF` (white text) | `#4A90D9` (steel blue) |
| No Vote | `#FFFFFF` (white text) | Neutral dark |

---

## Data Flow

### Vote Lifecycle (iOS → Firestore → Web)

```
1. User taps Happy on iOS
     │
2. TrackingViewModel.submitVote("happy")
     │
3. WriteBatch (atomic):
     ├── metrics/global_counts.total_happy += 1
     ├── metrics/global_counts.countries.{CC}.happy += 1
     └── users/{uid}.mood = "happy"
     │
4. batch.commit()
     │
5. Firestore propagates changes
     │
6. iOS: onSnapshot(users/{uid}) → updates TrackingView
7. Web: onSnapshot(users/{uid}) → updates AuraContent mood display
8. Web: onSnapshot(metrics/global_counts) → updates stats counters
```

### Account Deletion Flow (identical on both platforms)

```
1. retractVote() — if active mood exists
     │
     WriteBatch (atomic):
     ├── metrics/global_counts.total_{mood} -= 1
     ├── metrics/global_counts.countries.{CC}.{mood} -= 1
     └── users/{uid}.mood = ""
     │
2. deleteDoc(users/{uid})
     │
3. deleteUser(auth) — LAST (invalidates token)
```

> **Critical**: Auth deletion MUST be last. Firestore writes require a valid auth token. If auth is deleted first, the WriteBatch and deleteDoc calls will fail with `permission-denied`, leaving orphaned data.

---

## Firestore Schema & Rules

### Schema

```
metrics/global_counts
  ├── total_happy: Int
  ├── total_sad: Int
  └── countries: Map
        └── {CC}: Map           ← ISO 3166-1 alpha-2
              ├── happy: Int
              └── sad: Int

users/{uid}
  ├── mood: String              ← "happy" | "sad" | ""
  ├── country: String           ← ISO 3166-1 alpha-2
  └── updatedAt: Timestamp
```

### Security Rules

```
metrics/{doc}:
  READ:  anyone (if true)
  WRITE: authenticated only + field whitelist + type validation

users/{userId}:
  READ:  owner only (auth.uid == userId)
  WRITE: owner only (auth.uid == userId)

everything else:
  DENY ALL
```

Rule source: `firestore.rules`

---

## Design System

### Brand Identity
- **Logo**: `:)` / `:(` — two mirrored arcs sharing colon eyes (`SappyLogoShape.swift`)
- **Font**: Dela Gothic One (bold, geometric, cinematic)
- **Palette**: Black background, white text, mood-colored accents
- **Philosophy**: Radically minimalist. One question, one action, cinematic response.

### iOS Motion System
- **Spring animations**: `response: 0.7, dampingFraction: 0.65` (bouncy)
- **Idle breathing**: Scale 1.0 ↔ 1.012 (continuous 3s loop)
- **Staggered reveals**: 0.08s delay per element
- **Squishable buttons**: `SquishableButtonStyle` (scale 0.93 on press, spring return)
- **Vote cooldown**: 0.6s debounce on interaction

### Web Motion System
- **Orbital gradients**: Framer Motion `animate` with infinite rotation (20-30s duration)
- **SVG noise filter**: `feTurbulence` → `feDisplacementMap` for film grain texture
- **AnimatePresence**: Page transitions and modal enter/exit
- **Spring transitions**: `type: "spring"` on drawer and modal animations

---

## Deployment

### iOS
1. Xcode 15+ → Build → Archive → Upload to App Store Connect
2. `GoogleService-Info.plist` must be in `Sappy/` target
3. Minimum deployment: iOS 17.0

### Web Companion
1. `cd web && npm install && npm run build` — generates `web/out/`
2. `firebase deploy --only hosting` (from project root) — deploys `web/out/` to Firebase Hosting
3. Firebase config: `firebase.json` → `"hosting": { "public": "web/out" }`

### Firebase
- **Project**: `sappy-caa9e` (Europe, `eur3`)
- **Deploy rules**: `firebase deploy --only firestore:rules`
- **Deploy hosting**: `firebase deploy --only hosting`
