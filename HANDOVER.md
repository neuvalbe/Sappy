# Sappy — Agent Handover Document

> This is the handover document for AI agents working on Sappy. Read this first. Read it completely.

---

## Hard Rules

1. **No visual changes** unless explicitly requested
2. **No global installs** — `npm install` / `pnpm add` local only
3. **No git operations** unless explicitly commanded — no `git add`, `commit`, or `push`
4. **Every session producing changes** must conclude with updated `.md` documentation
5. **Source of truth is always the code** — documentation describes, code defines
6. **Radical candor** — no fluff, no filler, no empty praise

---

## Project Overview

| Attribute | Value |
|---|---|
| **Product** | Sappy — minimalist mood tracker |
| **Repo** | `/Users/neuvalstudio/Projects/Sappy` |
| **Platforms** | iOS 17+ (SwiftUI) + Web companion (Next.js 16, static export) |
| **Backend** | Firebase (`sappy-caa9e`, region `eur3`) |
| **Auth** | Sign In with Apple + Email/Password |
| **Database** | Cloud Firestore (real-time listeners on both platforms) |
| **Hosting** | Firebase Hosting (static export from `web/out/`) |

---

## File Map

### iOS App (`Sappy/`)

| File | Purpose |
|---|---|
| `SappyApp.swift` | @main entry, font registration |
| `SappyDesignTokens.swift` | Types (`AppState`, `Mood`), design tokens, `SquishableButtonStyle` |
| `ContentView.swift` | Root state router: `.login` ↔ `.tracking` |
| `AuthHelper.swift` | Post-auth logic: country persist + state transition |
| `LoginView.swift` | 2-step: country picker → sign-in options |
| `SappyAuthView.swift` | Email/password auth sheet |
| `SappyLegalView.swift` | Terms of Service + Privacy Policy (scrollable) |
| `TrackingView.swift` | Cinematic mood selection + feedback display |
| `TrackingViewModel.swift` | **Core logic**: Firestore sync, atomic votes, account lifecycle |
| `SappySettingsView.swift` | Sign-out + delete account |
| `SappyLogoShape.swift` | SVG path data for `:)` / `:(` logo |

### Web Companion (`web/`)

| File | Purpose |
|---|---|
| `src/lib/firebase.ts` | Firebase SDK init from `.env.local` |
| `src/app/layout.tsx` | Root layout, Dela Gothic One font, black bg |
| `src/app/page.tsx` | **State machine**: auth → Firestore listeners → render |
| `src/app/globals.css` | Tailwind config + overrides |
| `src/app/terms/page.tsx` | Public Terms of Service (no auth required) |
| `src/app/privacy/page.tsx` | Public Privacy Policy (no auth required) |
| `src/components/AuthModal.tsx` | Sign-in only (no sign-up) email/password form |
| `src/components/AuraBackground.tsx` | Framer Motion orbital gradients + SVG noise filter |
| `src/components/AuraContent.tsx` | Mood word, subtitle, global stats, country breakdown |
| `src/components/ProfileDrawer.tsx` | Profile info, legal docs, support, account management |

### Config & Admin

| File | Purpose |
|---|---|
| `firebase.json` | Firestore rules path + Hosting config (`"public": "web/out"`) |
| `firestore.rules` | Security rules (field-validated, type-checked) |
| `firestore.indexes.json` | Index definitions |
| `web/next.config.mjs` | Static export: `output: "export"`, `images.unoptimized: true` |
| `web/.env.local` | Firebase credentials (gitignored) |
| `read_firestore.js` | Admin: read `global_counts` |
| `seed_firestore.js` | Admin: wipe + re-seed |
| `wipe_firestore.js` | Admin: reset all data |

### Documentation

| File | Purpose |
|---|---|
| `README.md` | Project overview, structure, build instructions |
| `ARCHITECTURE.md` | Architecture guide, data flow, state machines |
| `TECH_SPECS.md` | Technical specs, file roles, resilience features |
| `HANDOVER.md` | This file — agent workflow + status tracker |

---

## Critical Data Flows

### 1. Vote Casting (iOS only)

```
User taps mood → TrackingViewModel.submitVote(mood)
  │
  ├── Same mood as current? → retractVote() (toggle off)
  ├── Different mood? → retractVote() then submitVote(new)
  └── No current mood? → submitVote(new)
  │
  WriteBatch (atomic):
    metrics/global_counts.total_{mood} += 1
    metrics/global_counts.countries.{CC}.{mood} += 1
    users/{uid}.mood = "{mood}"
    users/{uid}.updatedAt = serverTimestamp()
  │
  batch.commit() → Firestore propagates to all listeners
```

### 2. Real-Time Sync (both platforms)

```
iOS:  TrackingViewModel.listenToUserMood()      → onSnapshot(users/{uid})
iOS:  TrackingViewModel.listenToGlobalCounts()   → onSnapshot(metrics/global_counts)
Web:  page.tsx useEffect                         → onSnapshot(users/{uid})
Web:  page.tsx useEffect                         → onSnapshot(metrics/global_counts)
```

Both receive identical Firestore snapshots. Web is read-only for mood data.

### 3. Account Deletion (both platforms)

```
Step 1: Read users/{uid} → get current mood + country
Step 2: If active vote → WriteBatch retract (decrement global, clear mood)
Step 3: deleteDoc(users/{uid})
Step 4: deleteUser(auth) ← LAST (invalidates token)
```

**iOS**: Implemented in `TrackingViewModel.deleteAccount()` using callbacks
**Web**: Implemented in `ProfileDrawer.tsx handleDeleteAccount()` using async/await

> **CRITICAL**: Auth deletion MUST be step 4. If done earlier, Firestore writes fail with `permission-denied`, leaving orphaned vote counts in `global_counts`.

---

## What's Done ✅

### iOS App
- [x] Full MVVM architecture with `TrackingViewModel`
- [x] Sign In with Apple + Email/Password auth
- [x] Real-time Firestore listeners (user mood + global counts)
- [x] Atomic vote casting with `WriteBatch`
- [x] Vote retraction (toggle behavior)
- [x] Vote cooldown (0.6s debounce)
- [x] Country breakdown display (ISO 3166-1 capsules)
- [x] Cinematic UI (spring animations, breathing idle, staggered reveals)
- [x] Account deletion (Apple 5.1.1(v) compliant)
- [x] Terms of Service + Privacy Policy in-app
- [x] Post-auth country persistence via `AuthHelper`
- [x] Self-healing Firestore seed on first launch
- [x] State migration from pre-v1.5 UserDefaults

### Web Companion
- [x] Next.js 16 static export (`output: "export"`)
- [x] Auth modal (sign-in only, no sign-up)
- [x] Real-time Firestore listeners (user mood + global counts)
- [x] Ambient Aura background (orbital gradients + SVG noise)
- [x] Mood-reactive color scheme (happy=yellow, sad=blue)
- [x] Responsive typography and stats display
- [x] Public `/terms` and `/privacy` pages (no auth, App Store compliant)
- [x] Profile drawer with legal docs and account management
- [x] Account deletion with WriteBatch vote retraction
- [x] Dead code cleanup (removed 8 unused prototype components)
- [x] TypeScript 6 compatibility (removed deprecated `baseUrl`, fixed `moduleResolution`)

### Infrastructure
- [x] Firestore security rules (field-validated, type-checked)
- [x] Firebase Hosting config (`web/out/`)
- [x] Admin scripts (read, seed, wipe)
- [x] All 4 documentation files synchronized

---

## What's NOT Done ❌

| Item | Priority | Detail |
|---|---|---|
| **"Forgot Password"** | MEDIUM | Not implemented on either platform. Needs `Auth.auth().sendPasswordReset(withEmail:)` on iOS, `sendPasswordResetEmail()` on web. |
| **App Store screenshots** | HIGH | Required for submission: 6.7" and 6.5" mandatory. Not created yet. |
| **App Store metadata** | HIGH | Description, keywords, category, age rating not filled in Connect. |

---

## Build & Deploy Commands

### iOS
```bash
# Build in Xcode 15+
# Ensure GoogleService-Info.plist is in Sappy/ target
# Target: iOS 17.0+
```

### Web
```bash
cd web
npm install
npm run dev            # Local dev at localhost:3000
npm run build          # Static export to web/out/
```

### Deploy
```bash
# From project root
firebase deploy --only hosting        # Deploy web companion
firebase deploy --only firestore:rules  # Deploy security rules
```

### Admin
```bash
node read_firestore.js    # Read global_counts
node seed_firestore.js    # Wipe + re-seed
node wipe_firestore.js    # Reset all data
```

---

## Environment Variables

### Web (`web/.env.local`)
```
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=sappy-caa9e
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
```

### iOS
- `GoogleService-Info.plist` — bundled in target, gitignored

---

## Session Log

| Date | Session | Changes |
|---|---|---|
| 2026-03-24 | iOS Production Audit | Dead code removal, signOut race fix, full doc sync |
| 2026-03-28 | Web Companion Build | Auth modal, Ambient Aura, real-time listeners, profile drawer |
| 2026-03-29 | Web Finalization | WriteBatch deletion fix, static export config, TS6 compat, dead code purge, doc sync |
