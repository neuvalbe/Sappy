# Sappy — Architecture & React Replication Guide

> **Purpose**: This document provides everything a co-developer needs to replicate the Sappy iOS app in React (React Native or React web) for Android users. It covers the complete state machine, every screen's behavior, animation specifications, color values, typography, and the raw SVG path data for the logo.

---

## Table of Contents
1. [App Overview](#1-app-overview)
2. [File Structure](#2-file-structure)
3. [State Machine](#3-state-machine)
4. [Design System](#4-design-system)
5. [Screen-by-Screen Specification](#5-screen-by-screen-specification)
6. [Logo & SVG Path Data](#6-logo--svg-path-data)
7. [Animation Specifications](#7-animation-specifications)
8. [Haptic Feedback Map](#8-haptic-feedback-map)
9. [Persistence & Auth](#9-persistence--auth)
10. [React Implementation Notes](#10-react-implementation-notes)

---

## 1. App Overview

**Sappy** is a minimalist mood-tracking app. The user flow is:

```
Launch → Login Screen → Mood Selection ("happy" or "sad") → Feedback Message
```

The brand identity is the `):)` logo — a sad face `):(` and happy face `(:)` merged together, sharing the colon as eyes.

---

## 2. File Structure

```
Sappy/
├── SappyApp.swift            # @main entry point, custom font registration
├── SappyDesignTokens.swift   # Shared types (AppState, Mood), design tokens, SquishableButtonStyle
├── ContentView.swift         # Root state router — crossfades between login and tracking
├── LoginView.swift           # 2-step auth: country picker → Sign In (Sappy / Apple)
├── SappyAuthView.swift       # Email/password auth sheet (sign-up + sign-in)
├── SappyLegalView.swift      # Terms of Service & Privacy Policy sheet
├── TrackingView.swift        # Cinematic mood selection → feedback response
├── SappySettingsView.swift   # Account management: sign-out + account deletion
└── SappyLogoShape.swift      # SwiftUI Shape — SVG path data for ):) logo
```

**Project Root:**
```
SappyLogo.svg                 # Black stroke logo export (80×80)
```

### React Equivalent Structure
```
src/
├── App.jsx                   # Root — state router (replaces ContentView)
├── tokens.js                 # Design tokens from SappyDesignTokens
├── screens/
│   ├── LoginScreen.jsx       # Login flow (country + auth)
│   ├── AuthScreen.jsx        # Email/password auth modal
│   ├── TrackingScreen.jsx    # Cinematic mood selection + feedback
│   ├── SettingsScreen.jsx    # Account management: sign-out + deletion
│   └── LegalScreen.jsx       # Terms & Privacy Policy
├── components/
│   ├── SappyLogo.jsx         # SVG logo component
│   ├── SquishableButton.jsx  # Press-scale button
│   ├── SappyTextField.jsx    # Branded text input
│   └── FeedbackView.jsx      # Post-selection message
└── assets/
    └── sappy-logo.svg        # Logo SVG file
```

---

## 3. State Machine

### AppState Enum
```
enum AppState {
    case login    // Authentication flow
    case tracking // Cinematic mood selection → feedback
}
```

### Mood Enum
```
enum Mood: String {
    case happy = "happy"
    case sad = "sad"
}
```

### State Transitions
```
┌─────────┐    auth success    ┌──────────┐
│  LOGIN   │ ─────────────────>│ TRACKING │
└─────────┘                    └──────────┘
      ▲                              │
      │                        cinematic entrance
  sign out /                         │
  delete account                     ▼
      │                       ┌──────────────┐
      │                       │ MOOD SELECT  │ ← split faces, breathing idle
      │                       └──────────────┘
      │                              │
      │                          tap face
      │                              │
      │                              ▼
      │                       ┌──────────────┐
      │                       │   FEEDBACK   │ ← counter, empathetic message
      │                       └──────────────┘
      │                         │          │
      │                   "change answer"  ⚙ settings
      │                         │          │
      │                         ▼          ▼
      │                   ┌──────────┐  ┌──────────┐
      └───────────────────│MOOD SELECT│  │ SETTINGS │
                          └──────────┘  └──────────┘
```

---

## 4. Design System

All tokens are defined in `SappyDesignTokens.swift` → `SappyDesign` namespace.

### Colors
| Token | Value | Usage |
|---|---|---|
| `textPrimary` | `Color(white: 0.1)` ≈ `#1A1A1A` | Headlines, logo stroke |
| `textSecondaryOpacity` | `0.5` | Subtitles |
| `textTertiaryOpacity` | `0.4` | Disclaimers, labels |
| `textQuaternaryOpacity` | `0.3` | Hint text, chevrons |
| `inputBackgroundOpacity` | `0.04` | Input field fill |
| `inputBorderOpacity` | `0.1` | Input field border |
| `disabledOpacity` | `0.2` | Disabled button fill |
| `brandGradient` | `#FF3333 → #CC0000` | Selected mood faces |
| `happySubtitleColor` | `Color(red: 0.99, green: 0.87, blue: 0.03)` ≈ `#FDDE08` | "feels happy right now" text + glow (radius 8, 60% opacity) |
| `sadSubtitleColor` | `Color(red: 0.4, green: 0.55, blue: 0.78)` ≈ `#668CC7` | "feels sad right now" text + glow (radius 8, 50% opacity) |

### Typography
| Element | Size | Weight | Style |
|---|---|---|---|
| App title "sappy" | 32px | Bold | kerning: 4 |
| Mood words ("happy.", "sad.") | 48px | Light | italic, kerning: 1.5 |
| Feedback headline | 34px | Light | kerning: 1.2 |
| Feedback body | 18px | Regular | kerning: 0.8, lineSpacing: 6 |
| Center label | 16px | Regular | kerning: 1.2 |
| Auth header | 28px | Regular | — |
| Country/button text | 16-18px | Semibold/Bold | — |
| Disclaimer | 11px | Regular | — |

**Universal Font**: Dela Gothic One (bundled `DelaGothicOne-Regular.ttf`).

### Layout Constants
| Token | Value | Usage |
|---|---|---|
| `buttonHeight` | 56px | All buttons and inputs |
| `cornerRadius` | 16px | Buttons, inputs |
| `horizontalPadding` | 32px | Auth screen content |
| `bottomPadding` | 60px | Auth screen bottom |
| `trackingFaceSize` | 80px | Face logo frame |
| `trackingStrokeWidth` | 10px | Face stroke width |
| `splitDistance` | 180px | Vertical split distance |
| `selectedFaceOffset` | -180px | Selected face Y position |
| `dismissedFaceOffset` | 500px | Dismissed face Y exit |
| `selectedFaceScale` | 1.5× | Selected face scale |
| `feedbackContentOffset` | 80px | Feedback Y below face |

---

## 5. Screen-by-Screen Specification

### 5.1 Login Screen (`LoginView.swift`)

#### Layout (top to bottom)
1. **Background**: Pure white
2. **Logo**: `SappyLogoShape` — 80×80, stroked in `textPrimary`, with `.trim()` draw-on
3. **Title**: "sappy" — reveals left-to-right via mask scale synced to draw
4. **Subtitle**: "No app asks you how you feel."
5. **Spacer**
6. **Auth section** (two steps):

**Step 1 — Country Selection** (first-time users):
- "Where are you joining from?" label
- Country dropdown (Menu picker) with chevron
- "Continue" button (disabled until country selected)

**Step 2 — Sign-In Options** (after country or returning users):
- "Continue with Sappy" / "Sign In to Sappy" button (dark, with inline logo)
- "Sign in with Apple" native button (white outline)

7. **Disclaimer text**: links to legal sheet

#### Sheets
- `SappyAuthView` — email/password auth (sign-up + sign-in toggle)
- `SappyLegalView` — Terms of Service + Privacy Policy

### 5.2 Sappy Auth Sheet (`SappyAuthView.swift`)

Modal email/password form with:
- Header text (dynamic: "Create Account" / "Welcome Back")
- `SappyTextField` inputs: Name (sign-up only), Email, Password
- Submit button (disabled until form valid: non-empty fields + password ≥ 6)
- Toggle link: "Already have an account?" / "Don't have an account?"
- Dismiss button (X circle, top-left)

### 5.3 Legal Sheet (`SappyLegalView.swift`)

Scrollable document with:
- Terms of Service (4 sections)
- Privacy Policy (4 sections)
- `LegalSection` and `LegalParagraph` helper components

### 5.4 Tracking Screen (`TrackingView.swift`)

#### Cinematic Entrance (4 phases)

```
Phase 1 (0s):      Draw merged ):) logo via .trim() — 1.5s easeOut
Phase 2 (1.2s):    Spring-split into :) top / :( bottom — spring(0.8, 0.65) + soft haptic
Phase 3 (1.8s):    Fade in "happy.", "sad.", center label — 1.0s easeOut
Phase 4 (2.4s):    Start breathing animation — 3.5s easeInOut, repeating forever
```

#### Idle State
```
┌─────────────────────────────┐
│                             │
│         :)                  │  ← Happy face (colon + right arc)
│       happy.                │
│                             │
│  No app asks you how        │  ← Center label
│  you feel.                  │
│                             │
│       sad.                  │
│         :(                  │  ← Sad face (left arc + colon)
│                             │
└─────────────────────────────┘
```

Both faces breathe with opposite-phase scale (1.00 ↔ 1.02) and vertical oscillation (±8px).

#### Mood Selection
- Tap top half → select happy, tap bottom half → select sad
- Selected face: scales to 1.5×, moves to y: -180, applies `brandGradient` stroke
- Dismissed face: fades out, slides off-screen (±500px)
- Rigid haptic on selection
- Feedback content fades in with staggered delays (0.1s, 0.3s, 0.5s)

#### Feedback Content
| Mood | Headline | Body |
|---|---|---|
| Happy | "That's wonderful." | "Keep riding the wave.\nThe world is yours today." |
| Sad | "Take a deep breath." | "It is completely okay to feel this way.\nTomorrow is a new start." |

Plus: live real-time Firestore counter ("{count} people feel {mood} right now"), per-country breakdown capsules, and "Change my answer" reset button.

The subtitle "feels {mood} right now" is color-coded: **brand yellow** (`#FDDE08`) with a warm glow for happy, **steel blue** (`#668CC7`) with a cool glow for sad.

#### Reset Flow
- "Change my answer" → medium haptic
- Feedback fades out (0.4s)
- After 0.3s delay: spring reset to split idle state

---

## 6. Logo & SVG Path Data

### Logo Concept
The logo represents `):)` — reading left to right it's a sad face `):(`, but also a happy face `(:)`. The colon `:` serves as shared eyes.

### SVG Structure (3 parts)
| Part | Flag | Visual |
|---|---|---|
| Right Arc | `drawRight` | `)` — happy mouth |
| Colon | `drawColon` | `:` — shared eyes |
| Left Arc | `drawLeft` | `(` — sad mouth |

### Coordinate System
Raw path data spans a `104×134` unit region originating at `(202.6, 198.5)`. The `path(in:)` method normalizes coordinates into the target rect with uniform scaling and centering. The static `fullBounds` ensures partial compositions (e.g., colon-only) align spatially with the full logo.

---

## 7. Animation Specifications

| Animation | Duration | Easing | Delay | Notes |
|---|---|---|---|---|
| Logo stroke draw-on | 1.5s | easeOut | 0 | `.trim()`: 0 → 1 |
| Title/auth reveal | 1.0s | easeOut | 1.2s | opacity + offset(y: 20→0) |
| Auth step transition | spring | response: 0.5, damping: 0.7 | 0 | — |
| App state transition | 0.8s | easeInOut | 0 | opacity crossfade |
| Cinematic face split | spring | response: 0.8, damping: 0.65 | 1.2s | splitOffset: 0 → 180 |
| Text fade-in | 1.0s | easeOut | 1.8s | textOpacity: 0 → 1 |
| Breathing scale | 3.5s | easeInOut | 2.4s | 1.00 ↔ 1.02, forever |
| Breathing offset | 3.5s | easeInOut | 2.4s | ±8px, forever |
| Mood selection | spring | response: 0.6, damping: 0.7 | 0 | scale + gradient + offset |
| Feedback headline | 0.8s | easeOut | 0.1s | opacity + offset(y: 20→0) |
| Feedback counter | 0.8s | easeOut | 0.3s | opacity + offset(y: 20→0) |
| Feedback reset btn | 0.8s | easeOut | 0.5s | opacity + offset(y: 20→0) |
| Feedback fade-out | 0.4s | easeOut | 0 | on "Change my answer" |
| Mood reset | spring | response: 0.6, damping: 0.7 | 0.3s | selectedMood → nil |
| Button press scale | 0.2s | easeOut | 0 | scale: 1.0 → 0.96 |

---

## 8. Haptic Feedback Map

| Action | iOS API | Android Equivalent |
|---|---|---|
| Country selection | `UISelectionFeedbackGenerator.selectionChanged()` | `CLOCK_TICK` |
| "Continue" press | `UIImpactFeedbackGenerator(.medium)` | `CONTEXT_CLICK` |
| Auth success | `UINotificationFeedbackGenerator(.success)` | `CONFIRM` |
| Auth failure | `UINotificationFeedbackGenerator(.error)` | `REJECT` |
| Cinematic split | `UIImpactFeedbackGenerator(.soft)` | `CLOCK_TICK` |
| Mood selection | `UIImpactFeedbackGenerator(.rigid)` | `KEYBOARD_TAP` |
| Mood reset | `UIImpactFeedbackGenerator(.medium)` | `CONTEXT_CLICK` |

---

## 9. Persistence & Auth

### Firebase Backend (iOS — Production)
- **Project**: `sappy-caa9e` (region: `eur3`)
- **Auth Providers**: Sign In with Apple (via `OAuthProvider.appleCredential`) + Email/Password

### State Architecture (v2.0)

State is distributed across three independent stores. Understanding their lifecycle is critical:

| Store | Scope | Survives | Contains |
|---|---|---|---|
| **Firebase Auth** (Keychain) | Per-device, persists across app installs | App reinstall ✅ | Authentication session |
| **UserDefaults** | Per-device, persists across app builds | Clean build ✅, App delete ❌ | `currentMood` (cache), `userCountry` (cache), `hasCompletedFirstSignUp` (UX flag) |
| **Firestore `users/{uid}`** | Per-account, shared across devices | Forever (server) | `mood`, `country`, `updatedAt` — **source of truth** |
| **Firestore `metrics/global_counts`** | Global, single document | Forever (server) | `total_happy`, `total_sad`, `countries` map |

### Auth Flow
- `ContentView` checks `Auth.auth().currentUser` on launch → skips login if authenticated
- `LoginView` Step 1: Country picker (first-time users) → Step 2: Sign-In options
- Sign In with Apple: cryptographic nonce → `OAuthProvider.appleCredential(withIDToken:rawNonce:fullName:)`
- Email/Password: `Auth.auth().createUser()` or `signIn()` via `SappyAuthView`
- On auth success: `AuthHelper.completeAuthentication()` writes country to **both** `UserDefaults` and `Firestore users/{uid}`
- Country stored as **ISO 3166-1 alpha-2 code** (e.g. `"US"`, `"GB"`)

### Per-User Vote Deduplication (v2.0)

The vote state follows the **account**, not the device. This prevents double-counting when the same account is used across multiple devices (e.g., iPhone + Simulator).

**Firestore Collections:**
```
metrics/global_counts           ← Aggregated counts (public read, auth write)
  total_happy: Int
  total_sad: Int
  countries: Map<"US" → {happy: Int, sad: Int}>

users/{uid}                     ← Per-user vote state (owner read/write only)
  mood: String                  ← "happy" | "sad" | ""
  country: String               ← ISO 3166-1 alpha-2
  updatedAt: Timestamp
```

**Security Rules (v2.0 — field-validated):**
```
match /metrics/{doc} {
  allow read: if true;
  allow write: if request.auth != null
    && request.resource.data.keys().hasOnly(['total_happy', 'total_sad', 'countries'])
    && request.resource.data.total_happy is int
    && request.resource.data.total_sad is int;
}
match /users/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }
```

**Startup Sync (`startSync()`):**
1. Read `users/{uid}` from Firestore
2. If doc exists → hydrate `storedMood` and `storedCountry` from server (overwrites stale UserDefaults)
3. If doc missing but local state exists → migrate UserDefaults to Firestore
4. Ensure `metrics/global_counts` exists (self-healing seed)
5. Attach snapshot listener

**Vote Logic (`vote()` — atomic `WriteBatch`):**
- **Same mood**: No-op (guard)
- **Cooldown active**: No-op (0.6s debounce prevents rapid-fire corruption)
- **First vote**: `WriteBatch` — write mood to `users/{uid}` + increment total + country in `global_counts` (atomic)
- **Vote swap**: `WriteBatch` — write new mood to `users/{uid}` + decrement old + increment new in `global_counts` (atomic)

**Sign Out (`signOut()`):**
- Retract vote via atomic `WriteBatch` (decrement from `global_counts` + clear mood in `users/{uid}`)
- Clear `storedMood` only — **preserve** `userCountry` and `hasCompletedFirstSignUp` so returning users skip the country picker

**Account Deletion (`deleteAccount()` — sequential chain):**
1. Retract active vote via atomic `WriteBatch` (with completion handler)
2. Delete `users/{uid}` document (chained after retract completes)
3. Delete Firebase Auth account (chained after doc delete completes)
4. Clear ALL persisted state (full wipe)

Operations are chained sequentially via callbacks to prevent race conditions (e.g., auth token invalidation before retract can write to Firestore).

### Resilience Features (v2.0)
| Feature | Implementation |
|---|---|
| **Atomic writes** | All multi-document mutations use `WriteBatch` — user doc + global counts succeed or fail together |
| **Sequential delete** | `deleteAccount()` chains retract → doc delete → auth delete via callbacks |
| **Error logging** | All Firestore writes log failures via `[Sappy]`-prefixed console messages |
| **Count flooring** | `max(0, ...)` on all snapshot values — handles transient negatives from stale retracts |
| **Vote cooldown** | 0.6s `isVoteCooldown` flag — prevents rapid-tap race conditions |
| **Country stat guardrail** | If `countryStats` is empty but user just voted, show their country with count 1 — eliminates async timing gap between Firestore write and snapshot delivery |
| **Field-validated rules** | `metrics` writes restricted to known fields (`total_happy`, `total_sad`, `countries`) with type validation |
| **Self-healing seed** | `startSync()` creates `global_counts` if missing |
| **Migration path** | Local-only state (pre-v1.5) automatically migrated to `users/{uid}` on first sync |

### React Native Equivalent
```jsx
import auth from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';

// Auth
await auth().createUserWithEmailAndPassword(email, password);

// Read user's vote state on login
const userDoc = await firestore().collection('users').doc(uid).get();
if (userDoc.exists) {
  const { mood, country } = userDoc.data();
  // Hydrate local state from server
}

// Fresh vote — atomic WriteBatch: user doc + global counts
const batch = firestore().batch();
const userRef = firestore().collection('users').doc(uid);
const metricsRef = firestore().collection('metrics').doc('global_counts');

batch.set(userRef,
  { mood: 'happy', country: 'US', updatedAt: firestore.FieldValue.serverTimestamp() },
  { merge: true }
);
batch.update(metricsRef, {
  total_happy: firestore.FieldValue.increment(1),
  'countries.US.happy': firestore.FieldValue.increment(1)
});
await batch.commit();

// Vote Swap — atomic WriteBatch: decrement old + increment new
const swapBatch = firestore().batch();
swapBatch.set(userRef,
  { mood: 'happy', updatedAt: firestore.FieldValue.serverTimestamp() },
  { merge: true }
);
swapBatch.update(metricsRef, {
  total_sad: firestore.FieldValue.increment(-1),
  'countries.US.sad': firestore.FieldValue.increment(-1),
  total_happy: firestore.FieldValue.increment(1),
  'countries.US.happy': firestore.FieldValue.increment(1)
});
await swapBatch.commit();
```



---

## 10. React Implementation Notes

### Key Mappings

| SwiftUI | React |
|---|---|
| `ZStack` | `position: absolute` / `z-index` |
| `.transition(.opacity)` | `<AnimatePresence>` with `initial/animate/exit` |
| `spring(response: X, dampingFraction: Y)` | `transition={{ type: "spring", duration: X, bounce: 1-Y }}` |
| `@State` | `useState` |
| `@Binding var` | prop + setter callback |
| `.onAppear` | `useEffect(() => {}, [])` |
| `@AppStorage` | `AsyncStorage` (RN) / `localStorage` (web) |
| `NavigationStack` + `.sheet` | React Navigation modal / dialog |
| `Menu` picker | `@react-native-picker/picker` or custom dropdown |
| `SignInWithAppleButton` | `@invertase/react-native-apple-authentication` |

### Minimum Dependencies (React Native)
```json
{
  "react-native-svg": "^15.x",
  "react-native-reanimated": "^3.x",
  "react-native-haptic-feedback": "^2.x",
  "@react-native-async-storage/async-storage": "^1.x",
  "@invertase/react-native-apple-authentication": "^2.x",
  "@react-native-picker/picker": "^2.x"
}
```
